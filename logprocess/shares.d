module logprocess.shares;

import std.stdio;
//import std.regexp;
import std.file;
import std.date;
import std.string:atoi;
import std.string:join;
import icere.regexp;

import logprocess.alogprocessor;

class Shares : public ALogProcessor
{
protected:
	enum ShareType {Share=0, Back, Permanent};
	d_time[char[]][ShareType] Shares;
	d_time[][char[]] ShareTimes;
	d_time logstart_ts;
	char[] lastline;
	RegExp ExtractTime, ExtractTimeSimple, Share, Unshare, GetShare, GetUnshare, Endlog;
public:
	this()
	{
	}
	void Reset()
	{
		ShareTimes = null;
		Shares[ShareType.Share] = null;
		Shares[ShareType.Back] = null;
		Shares[ShareType.Permanent] = null;
	}
	void Create(AtlpCfg cfg)
	{
		ExtractTime = parent.regexps["TimestampFull"];
		ExtractTimeSimple = parent.regexps["TimestampSimple"];
		Share = parent.regexps["YouShare"];
		Unshare = parent.regexps["YouDontShare"];

		GetShare = parent.regexps["YouGetShared"];
		GetUnshare = parent.regexps["YouDontGetShared"];

		Endlog = parent.regexps["EndLog"];
		
		logstart_ts = 0;
		lastline = "";
	}
	void ProcessLine(char[] line)
	{
		lastline = line;
		auto m = Share.execute(line);
		if (m)
		{
			StartShareWith(m.group("char"), m.group("arts"));
			return;
		}
		m = Unshare.execute(line);
		if (m)
		{
			StopShareWith(m.group("char"), m.group("arts"));
			return;
		}
		
		m = GetShare.execute(line);
		if (m)
		{
			StartShareFrom(m.group("char"), m.group("arts"));
			return;
		}
		m = GetUnshare.execute(line);
		if (m)
		{
			StopShareFrom(m.group("char"), m.group("arts"));
			return;
		}
		
		
		m = Endlog.execute(line);
		if (m)
		{
			OnCloseLogFile();
			return;
		}
	}
	void OnCloseLogFile()
	{
		logstart_ts = 0;
		auto m = ExtractTimeSimple.execute(lastline);
		foreach (name, time; Shares[ShareType.Share])
		{
			StopShareWith(name, m.group("arts"));
		}
		foreach (name, time; Shares[ShareType.Back])
		{
			StopShareFrom(name, m.group("arts"));
		}
	}
	void OnOpenLogFile()
	{
	}
	//1.1.2008 0:00:00
	protected void StartShareWith(char[] Player, char[] arts)
	{
		auto mts = ExtractTime.execute(arts);
		Shares[ShareType.Share][Player] = parent.ArindalTsToDate(mts);
	}
	protected void StartShareFrom(char[] Player, char[] arts)
	{
		auto mts = ExtractTime.execute(arts);
		Shares[ShareType.Back][Player] = parent.ArindalTsToDate(mts);
	}
	protected void StartPermaShare(char[] Player, char[] arts)
	{
		auto mts = ExtractTime.execute(arts);
		Shares[ShareType.Permanent][Player] = parent.ArindalTsToDate(mts);
	}
	protected void StopShareWith(char[] Player, char[] arts)
	{
		if (!(Player in ShareTimes)) ShareTimes[Player] = [0L,0L,0L];
		if (!(Player in Shares[ShareType.Share])) return;
		auto mts = ExtractTime.execute(arts);
		ShareTimes[Player][ShareType.Share] += (parent.ArindalTsToDate(mts) - Shares[ShareType.Share][Player]);
		Shares[ShareType.Share].remove(Player);
	}
	protected void StopShareFrom(char[] Player, char[] arts)
	{
		if (!(Player in ShareTimes)) ShareTimes[Player] = [0L,0L,0L];
		if (!(Player in Shares[ShareType.Back])) return;
		auto mts = ExtractTime.execute(arts);
		ShareTimes[Player][ShareType.Back] += (parent.ArindalTsToDate(mts) - Shares[ShareType.Back][Player]);
		Shares[ShareType.Back].remove(Player);
	}
	public long[][char[]] GetShareTimes()
	{
		return ShareTimes;
	}
	public char[][][char[]] GetShares()
	{
		char[][][char[]] ShareStrings;
		foreach (Player, share; ShareTimes)
		{
			ShareStrings[Player] = ["", "", ""];
			foreach (type, time; share)
			{
				ShareStrings[Player][type] = GetTimeString(time);
			}
		}
		return ShareStrings;
	}
	char[] GetName()
	{
		return "login time stats";
	}
	
	void PrintStats()
	{
		writefln("\nLogin Time Stats\n---------");

	}
	char[] GetStats()
	{
		return "";
	}
	
	char[] GetTimeString(long msecs)
	{
		long restOnlineTime = msecs / 1000;
		const int secondsInDay = (24*60*60);
		const int secondsInHour = (60*60);
		const int secondsInMinute = 60;
		auto totalhours = restOnlineTime/secondsInHour;
		auto days = restOnlineTime/secondsInDay;
		restOnlineTime -= days*secondsInDay;
		auto hours = restOnlineTime/secondsInHour;
		restOnlineTime -= hours*secondsInHour;
		auto minutes = restOnlineTime/secondsInMinute;
		restOnlineTime -= minutes*secondsInMinute;

		return std.string.format("%dd %dh %dm %ds", days, hours, minutes, restOnlineTime);
	}
}