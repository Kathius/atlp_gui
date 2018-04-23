module logprocess.atextlogcollection;

import std.stdio;
import std.file;
//import std.regexp;
import std.date;
import std.stream;
import std.string;
import wx.wx;
import icere.regexp;

public import logprocess.regexps;

public struct AtlpCfg
{
	char[] Path;
	char[] Charname;
	AtlpLanguage lang;
};

public import logprocess.alogprocessor;
public import logprocess.arankcounter;
public import logprocess.killcounter;
public import logprocess.milestones;
public import logprocess.personalstats;
public import logprocess.fallentos;
public import logprocess.hunts;
public import logprocess.logintime;

version (Win32)
{
	/* "stolen" from phobos.std.file */
	private import std.c.windows.windows;
	private import std.utf;
	private import std.windows.syserror;
	private import std.windows.charset;
	private import std.date;

	int useWfuncs = 1;

	static this()
	{
	    // Win 95, 98, ME do not implement the W functions
	    useWfuncs = (GetVersion() < 0x80000000);
	}
}


class ATextlogCollection
{
protected:
	char[] ArindalRootDir;
	char[] TextlogDir;
	char[] Character;
	AtlpCfg cfg;
	ALogProcessor[] Procs;
public:
	//const char[] reTimestamp = r"(?:(?P<month>\d\d?)/(?P<day>\d\d?)/(?P<year>\d\d) (?P<hour>\d\d?):(?P<minute>\d\d):(?P<second>\d\d)(?P<ap>a|p) )";
	RegExp retime;
	RegExps regs;
	RegExp[char[]] regexps;
	char[][] Trainers;
public:
	~this()
	{
		/*
		foreach (reg; regexps)
		{
			delete reg;
			delete retime;
		}
		*/
	}
	this()
	{
		regs = new RegExps(); /* load the regexp holder */

		/* assemble trainer list */

		Trainers ~= regs.Trainers.keys;

	}
	void Init(AtlpCfg cfg)
	{
		this.cfg = cfg;
		ArindalRootDir = cfg.Path;
		Character = cfg.Charname;
		TextlogDir = ArindalRootDir ~ "/data/Text Logs/" ~ Character;

		char[] retrn = Trainers.join("|");
		/* find charname */
		auto files = std.file.listdir(TextlogDir, std.regexp.RegExp("CL Log"));
		auto wbreg = new RegExp(regs.regexps["StartLogFindChar"][cfg.lang]);
		wbreg.study();
		seekfile: foreach (file; files)
		{
			auto content = cast(char[])ReadLogFile(file);
			auto lines = std.regexp.split(content, "\r?\n|\r");
			foreach (line; lines)
			{
				if (!line) continue;
				auto m = wbreg.execute(line);
				if (m)
				{
					Character = m.group("charname");
					this.cfg.Charname = Character;
					break seekfile;
				}
			}
		}

		/* -- */
		try
		{
			/* fetch regexps; depending on chosen language */
			foreach (regname, reglangs; regs.regexps)
			{
				char[] finalregex="";
				if (AtlpLanguage.all in reglangs)
				{
					finalregex =  reglangs[AtlpLanguage.all];
				}else if (cfg.lang == AtlpLanguage.all)
				{
					char[][] allreg;
					//foreach (reglang; reglangs) allreg ~= "(?:"~reglang~")";
					/*TODO: gotta try out if above works */
					for (auto iLang = AtlpLanguage.all+1; iLang < AtlpLanguage.max; iLang++)
					{
						if (cast(AtlpLanguage)iLang in reglangs) allreg ~= "(?:"~reglangs[cast(AtlpLanguage)iLang]~")";
					}
					finalregex = allreg.join("|");
				}else
				{
					if (!(cfg.lang in reglangs))
					{
						MessageBox("Couldn't find language specific string for regex \""~regname~"\"");
						finalregex = "^$";
					}else
					{
						finalregex = reglangs[cfg.lang];
					}
				}
				finalregex = std.string.replace(finalregex, "!CHARNAME!", Character);
				finalregex = std.string.replace(finalregex, "!TRAINERS!", retrn);
				switch (regname)
				{
				case "YouDontShare":
					//wx.wx.MessageBox(finalregex);
				default: break;
				}
				try
				{
					if (regname in regexps) regexps.remove(regname);
					regexps[regname] = new RegExp(finalregex);
					regexps[regname].study();
				}catch (CompileTimeException e)
				{
					MessageBox("Exc: " ~ e.msg ~ "(" ~ std.string.toString(e.code) ~"):\n" ~ finalregex);
				}
			}
			//retime = new RegExp("^" ~ reTimestamp);
			retime = regexps["TimestampFull"];
			//retime.study();
		}catch (Exception e)
		{
			MessageBox("Exc: " ~ e.msg);
		}
	}
	void AttachLoglineProcessor(ALogProcessor proc)
	{
		Procs ~= proc;
		proc.parent = this;
		proc.Create(cfg);
	}
	void DetachAllProcessors()
	{
		Procs = null;
	}
	alias void delegate(uint) spf;
	alias bool delegate(uint, char[]) upf;
	alias void delegate(d_time) epf;
	bool ProcessFiles(spf OnStartProcessing=null, upf OnUpdate=null, epf OnEndProcessing=null)
	{
		bool canceled=false;
		auto files = std.file.listdir(TextlogDir, std.regexp.RegExp("CL Log"));
		files.sort;
		if (OnStartProcessing) OnStartProcessing(files.length);
		uint iFile=0;
		RegMatch lasttime;
		foreach (file; files)
		{
			try
			{
				iFile++;
				if (OnUpdate) if (!OnUpdate(iFile, file)) break;
				if (canceled) break;
				auto content = cast(char[])ReadLogFile(file);
				auto lines = std.regexp.split(content, "\r?\n|\r");
				foreach (lp; Procs) lp.OnOpenLogFile();
				foreach(line;lines)
				{
					auto m = retime.execute(line);
					if (!m) continue;
					lasttime = m;
					foreach (lp; Procs) lp.ProcessLine(line);
				}
				foreach (lp; Procs) lp.OnCloseLogFile();
			}catch (Exception e)
			{
				continue;
			}
		}
		std.gc.fullCollect();
		if (OnEndProcessing) OnEndProcessing(ArindalTsToDate(lasttime));
		return true;
	}
	d_time ArindalTsToDate(RegMatch m)
	{
		if (!m) return 0;
		char[] strdate = std.string.format("20%s-%s-%s %s:%s:%s%sm",
			m.group("year"), m.group("month"), m.group("day"),
			m.group("hour"), m.group("minute"), m.group("second"), m.group("ap"));
		return std.date.parse(strdate);
	}
	void ProcessFiles(d_time start=0, d_time end=0, spf OnStartProcessing=null, upf OnUpdate=null, epf OnEndProcessing=null)
	{
		if (start == 0 && end == 0)
		{
			ProcessFiles(OnStartProcessing, OnUpdate, OnEndProcessing);
			return;
		}
		auto files = std.file.listdir(TextlogDir, std.regexp.RegExp("CL Log"));
		files.sort;
		if (OnStartProcessing) OnStartProcessing(files.length);
		RegMatch lasttime;
		uint iFile=0;
		foreach (file; files)
		{
			iFile++;
			if (OnUpdate) if (!OnUpdate(iFile, file)) break;
			auto reFiledate = new RegExp(r"^(.*)CL Log (\d\d\d\d)-(\d\d)-(\d\d) (\d\d)\.(\d\d)\.(\d\d)\.txt$");
			auto filedate = reFiledate.replace(file, new RegTemplate(r"\2-\3-\4 \5:\6:\7"));
			// If the format is wrong, skip this file
			if (filedate == file) continue;

			auto filetimestamp = std.date.parse(filedate);

			int diff = 2 * 24 * 60 * 60 * 1000; // 2 days
			// if the first line is more than 2 days before our startdate
			// it is very unlikely that ANY timestamp is within range
			// so skip this file
			if (start > 0 && (filetimestamp+diff) < start)
			{
				continue;
			}
			// if the first line is after our enddate, the whole file is
			// obviously too new, so skip it
			if (end > 0 && filetimestamp > end)
			{
				continue;
			}

			try
			{
				auto content = cast(char[])ReadLogFile(file);
				auto lines = std.regexp.split(content, r"\r?\n|\r");

				// if the first line is not more than 2 days before the end date
				// it is possible that a later timestamp in that file is already
				// behind the end date
				// if the first line is before our start date, it is possible that
				// a later timestamp in that file is still after the start date
				// in both cases we have to check every timestamp in that file
				if (end > 0 && filetimestamp+diff > end || start > 0 && filetimestamp < start)
				{
					// find out the first non-empty line
					int startline=0;
					while (lines[startline]=="") startline++;

					// if there are no timestamps, we cannot use this file
					auto m = retime.execute(lines[startline]);
					if (!m)
					{
						continue;
					}
					foreach (lp; Procs) lp.OnOpenLogFile();
					/* now check each line's timestamp before processing */
					for (int i=startline;i<lines.length;i++)
					{
						auto line = lines[i];
						m = retime.execute(line);
						if (!m) continue; // if there is no timestamp, we can't use this line
						auto linetime = ArindalTsToDate(m);
						if ((start == 0 || start <= linetime) && (end == 0 || linetime <= end))
						{
							lasttime = m;
							foreach (lp; Procs) lp.ProcessLine(line);
						}
					}
					foreach (lp; Procs) lp.OnCloseLogFile();
				}else // file doesn't have to be checked
				{
					foreach (lp; Procs) lp.OnOpenLogFile();
					foreach (line;lines)
					{
						auto m = retime.execute(line);
						if (!m) continue;
						lasttime = m;
						foreach (lp; Procs) lp.ProcessLine(line);
					}
					foreach (lp; Procs) lp.OnCloseLogFile();
				}
			}catch (Exception e)
			{
				writefln(e.toString());
				continue;
			}
		}
		std.gc.fullCollect();
		if (OnEndProcessing) OnEndProcessing(ArindalTsToDate(lasttime));
	}
	void[] ReadLogFile(char[] name)
	{
		version (Win32)
		{
			/* "stolen" from phobos.std.file */
		    DWORD numread;
		    HANDLE h;

		    if (useWfuncs)
		    {
			wchar* namez = std.utf.toUTF16z(name);
			h = CreateFileW(namez,GENERIC_READ,FILE_SHARE_READ | FILE_SHARE_WRITE,null,OPEN_EXISTING,
			    FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN,cast(HANDLE)null);
		    }
		    else
		    {
			char* namez = std.windows.charset.toMBSz(name);
			h = CreateFileA(namez,GENERIC_READ,FILE_SHARE_READ | FILE_SHARE_WRITE,null,OPEN_EXISTING,
			    FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN,cast(HANDLE)null);
		    }

		    if (h == INVALID_HANDLE_VALUE)
			goto err1;

		    auto size = GetFileSize(h, null);
		    if (size == INVALID_FILE_SIZE)
			goto err2;

		    auto buf = std.gc.malloc(size);
		    if (buf)
			std.gc.hasNoPointers(buf.ptr);

		    if (ReadFile(h,buf.ptr,size,&numread,null) != 1)
			goto err2;

		    if (numread != size)
			goto err2;

		    if (!CloseHandle(h))
			goto err;

		    return buf[0 .. size];

		err2:
		    CloseHandle(h);
		err:
		    delete buf;
		err1:
		    throw new FileException(name, GetLastError());
		}else /* !Win32 */
		{
			return read(name);
		}
	}

};
