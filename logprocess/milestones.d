module logprocess.milestones;

import std.stdio;
//import std.regexp;
import std.file;
import std.string:atoi;
import std.string:join;
import icere.regexp;

import logprocess.alogprocessor;
import logprocess.arankcounter;

class Milestones : public ALogProcessor
{
protected:
	RegExp retitle;
	char[][char[]] TitleTimes;
	char[] Charname;
public:
	this()
	{
	}
	void Create(AtlpCfg cfg)
	{
		Charname = cfg.Charname;
		retitle = parent.regexps["TitleMessage"];
	}
	void ProcessLine(char[] line)
	{
		auto m = retitle.execute(line);
		if (m)
		{
			if (!(m.group("title") in TitleTimes)) TitleTimes[m.group("title")] = m.group("arts");
		}
	}
	char[] GetName()
	{
		return "milestones";
	}

	void PrintStats()
	{
		writefln("\nMilestones\n----------");
		foreach (title, time; TitleTimes)
		{
			writefln("%s: %s", title, time);
		} 
	}
};