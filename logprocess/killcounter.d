module logprocess.killcounter;

import std.stdio;
//import std.regexp;
import std.file;
import std.string:atoi;
import std.string:join;
import icere.regexp;

import logprocess.alogprocessor;

class KillCounter : public ALogProcessor
{
protected:
	RegExp rekill;
	int[][char[]] Kills;
	char[][][char[]] KillTimes;
public:
	
	
public:
	public void Create(AtlpCfg cfg)
	{
		rekill = parent.regexps["MonsterKilltype"];
	}
	public void Reset()
	{
		Kills = null;
		KillTimes = null;
	}
	void ProcessLine(char[] line)
	{
		auto m = rekill.execute(line);
		if (m)
		{
			auto monster = m.group("monster");
			if (!(monster in Kills))
			{
				Kills[monster] = [0,0,0,0,0,0,0,0];
				KillTimes[monster] = ["", "", "", ""];
			}
			switch (m.group("killtype"))
			{
			/* solo kills */
			case "geschlachtet":
			case "slaughtered":
				Kills[monster][0]++;
				if (KillTimes[monster][0] == "") KillTimes[monster][0] = m.group("arts");
				break;
			case "erlegt":
			case "dispatched":
				Kills[monster][1]++;
				if (KillTimes[monster][0] == "") KillTimes[monster][1] = m.group("arts");
				break;
			case "getötet":
			case "killed":
				Kills[monster][2]++;
				if (KillTimes[monster][0] == "") KillTimes[monster][2] = m.group("arts");
				break;
			case "bezwungen":
			case "vanquished":
				Kills[monster][3]++;
				if (KillTimes[monster][0] == "") KillTimes[monster][3] = m.group("arts");
				break;
			/* group kills */
			case "zu schlachten":
			case "helped to slaughter":
				Kills[monster][4]++;
				if (KillTimes[monster][0] == "") KillTimes[monster][0] = m.group("arts");
				break;
			case "zu erlegen":
			case "helped to dispatch":
				Kills[monster][5]++;
				if (KillTimes[monster][0] == "") KillTimes[monster][1] = m.group("arts");
				break;
			case "zu töten":
			case "helped to kill":
				Kills[monster][6]++;
				if (KillTimes[monster][0] == "") KillTimes[monster][2] = m.group("arts");
				break;
			case "zu bezwingen":
			case "helped to vanquish":
				Kills[monster][7]++;
				if (KillTimes[monster][0] == "") KillTimes[monster][3] = m.group("arts");
				break;
			default: break;
			}
		}		
	}
	char[] GetName()
	{
		return "kill counter";
	}
	public int[][char[]] GetKills()
	{
		return Kills;
	}
	public char[][][char[]] GetKillTimes()
	{
		return KillTimes;
	}
	void PrintStats()
	{
		writefln("\nKills\n-----");
		foreach (Monster, arKills; Kills)
		{
			writefln("%s: %d, %d, %d, %d, %d, %d, %d, %d", 
				Monster,
				arKills[0], arKills[1], arKills[2], arKills[3], 
				arKills[4], arKills[5], arKills[6], arKills[7]);
		}
	}
	void PrintKilltimes()
	{
		writefln("\nFirst Kills\n-----------");
		foreach (Monster, arKills; KillTimes)
		{
			writefln("%s: %s, %s, %s, %s", 
				Monster,
				arKills[0], arKills[1], arKills[2], arKills[3]);
		}
	}
}