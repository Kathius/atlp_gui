module logprocess.collisseum;

import std.stdio;
//import std.regexp;
import std.file;
import std.date;
import std.string:atoi;
import std.string:join;
import icere.regexp;

import logprocess.alogprocessor;

class CollisseumFights : public ALogProcessor
{
protected:
	RegExp recol1, recol2, recol3, recol4;
	int[][char[]] Fights;
	uint colistate = 0;
	char[] curmonster;

public:
	public void Create(AtlpCfg cfg)
	{
		recol1 = parent.regexps["CollisseumChoose"];
		recol2 = parent.regexps["CollisseumStartfight"];
		recol3 = parent.regexps["CollisseumWin"];
		recol4 = parent.regexps["CollisseumLose"];
		//wx.wx.MessageBox(parent);
	}
	void Reset()
	{
		Fights = null;
		colistate = 0;
	}
	void ProcessLine(char[] line)
	{
		RegMatch m;
		switch (colistate)
		{
		case 0:
			m = recol1.execute(line);
			if (m)
			{
				colistate = 1;
				curmonster = m.group("number") ~ " " ~ m.group("monster");
			}
			break;
		case 1:
			m = recol2.execute(line);
			if (m) colistate = 2;
			break;
		case 2:
			m = recol3.execute(line);
			if (m) /* win */
			{
				if (!(curmonster in Fights)) Fights[curmonster] = [0,0];
				Fights[curmonster][0]++;
				colistate = 0;
				break;
			}
			m = recol4.execute(line);
			if (m) /* lose */
			{
				if (!(curmonster in Fights)) Fights[curmonster] = [0,0];
				Fights[curmonster][1]++;
				colistate = 0;
				break;
			}
		default: break;
		}		
	}
	char[] GetName()
	{
		return "coli";
	}
	
	int[][char[]] GetFights()
	{
		return Fights;
	}
	void PrintFallenTos()
	{
		writefln("\nFallen To\n---------");
		writefln(GetStats());
	}
	char[] GetStats()
	{
		char[] output;
		/*
		foreach (Monster, Number; FallenTos)
		{
			output ~= std.string.format("%s: %d", Monster, Number[0]);
		}
		*/
		return output;
	}
}