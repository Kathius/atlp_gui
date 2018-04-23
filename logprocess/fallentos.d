module logprocess.fallentos;

import std.stdio;
//import std.regexp;
import std.file;
import std.date;
import std.string:atoi;
import std.string:join;
import icere.regexp;

import logprocess.alogprocessor;

class FallenTos : public ALogProcessor
{
protected:
	RegExp refallen, redepart1, redepart2;
	int[][char[]] FallenTos;
	uint departstate = 0;
	d_time departtime = 0;
	char[] fallento;

public:
	public void Create(AtlpCfg cfg)
	{
		refallen = parent.regexps["FallenMessage"];
		redepart1 = parent.regexps["DepartMessage1"];
		redepart2 = parent.regexps["DepartMessage2"];
	}
	void Reset()
	{
		FallenTos = null;
	}
	void ProcessLine(char[] line)
	{
		auto m = refallen.execute(line);
		if (m)
		{
			auto monster = m.group("monster");
			if (!(monster in FallenTos))
			{
				FallenTos[monster] = [0, 0];
			}
			fallento = monster;
			FallenTos[monster][0]++;
		}
		
		RegMatch mz;
		if (departstate == 1)
		{
			mz = parent.retime.execute(line);
			if (!mz) departstate = 0;
			if ((parent.ArindalTsToDate(mz) - departtime) > 5000) departstate = 0;
		}
		switch (departstate)
		{
		case 0:
			m = redepart1.execute(line);
			if (m)
			{
				departstate = 1;
				mz = parent.retime.execute(line);
				departtime = parent.ArindalTsToDate(mz);
			}
			break;
		case 1:
			m = redepart2.execute(line);
			if (m)
			{
				departstate = 0;
				departtime = 0;
				if (!(fallento in FallenTos))
				{
					FallenTos[fallento] = [0, 0];
				}
				FallenTos[fallento][1]++;
			}
			break;
		default: break;
		}		
	}
	char[] GetName()
	{
		return "fallen";
	}
	
	int[][char[]] GetFallenTos()
	{
		return FallenTos;
	}
	void PrintFallenTos()
	{
		writefln("\nFallen To\n---------");
		writefln(GetStats());
	}
	char[] GetStats()
	{
		char[] output;
		foreach (Monster, Number; FallenTos)
		{
			output ~= std.string.format("%s: %d", Monster, Number[0]);
		}
		return output;
	}
}