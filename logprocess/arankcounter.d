module logprocess.arankcounter;

import std.stdio;
//import std.regexp;
import std.file;
import std.string:atoi;
import std.string:join;
import icere.regexp;
import wx.wx;
import logprocess.alogprocessor;

class ARankCounter : ALogProcessor
{
public:
	static RegExp resysmsg, retrnmsg, retrnchs;
protected:
	int[char[]] Ranks;
	bool simple=false;
	char[] CurrentTrainer;
	char[][][char[]] SysMsgMap;
public:
	this(bool Simple=false)
	{
		simple = Simple;
	}
	void Create(AtlpCfg cfg)
	{
		resysmsg = parent.regexps["SystemRankMessage"];
		retrnmsg = parent.regexps["TrainerProgressMessage"];
		retrnchs = parent.regexps["TrainerChosenMessage"];
		SysMsgMap = null;
		foreach (trainer, trninfo; parent.regs.Trainers)
		{
			if (!(trninfo.Message in SysMsgMap)) SysMsgMap[trninfo.Message] = null;
			SysMsgMap[trninfo.Message] ~= trainer;
		}
		systrn: foreach(trainer; parent.Trainers)
		{
			foreach (trn, num; Ranks) if (trn == trainer) continue systrn;
			Ranks[trainer] = 0;
		}
	}
	public void Reset()
	{
		CurrentTrainer = "";
		foreach (trn, num; Ranks) Ranks[trn] = 0;
	}
	void ProcessLine(char[] content)
	{
		auto m = resysmsg.execute(content);
		if (m)
		{
			CheckGameMessage(m.group("msg"));
			return;
		}
		if (!simple)
		{
			m = retrnmsg.execute(content);
			if (m)
			{
				CheckTrainerMessage(m.group("trainer"), m.group("msg"));
				return;
			}
		}
		m = retrnchs.execute(content);
		if (m)
		{
			CurrentTrainer = m.group("trainer");
			return;
		}
	}
	void CheckGameMessage(char[] msg)
	{
		if (msg in SysMsgMap)
		{
			if (SysMsgMap[msg].length > 1)
			{
				foreach (trainer; SysMsgMap[msg])
				{
					if (trainer == CurrentTrainer)
					{
						Ranks[CurrentTrainer]++;
						return;
					}
				}
			}
			Ranks[SysMsgMap[msg][0]]++;
		}
	}
	void CheckTrainerMessage(char[] trainer, char[] msg)
	{
		if (msg in parent.regs.TrnMsgMap)
		{
			Ranks[trainer] = (Ranks[trainer] > parent.regs.TrnMsgMap[msg]) ? Ranks[trainer] : parent.regs.TrnMsgMap[msg];
		}
	}
	void PrintStats()
	{
		if (simple)	writefln("\nRanks (simple)\n--------------");
		else writefln("\nRanks\n-----");
		writefln(GetStats());
	}
	public char[] GetStats()
	{
		char[] output;
		char[][] classnames = ["Common", "Healer", "Fighter", "Mage", "Secondary", "Languages"];
		int total=0;
		for (auto type=ArindalClass.Common; type<ArindalClass.totalsize; type++)
		{
			int classtotal = 0;
			char[] classoutput = "";
			foreach (trn, rnk; Ranks)
			{
				if (parent.regs.Trainers[trn].Class != type) continue;
				classtotal += rnk;
				total += rnk;
				if (rnk > 0)
				{
					classoutput ~= "  " ~ (trn == CurrentTrainer ? "*" : "") ~ trn ~ ": " ~
						std.string.toString(rnk) ~
						(parent.regs.Trainers[trn].MaxRanks ? " / " ~ std.string.toString(parent.regs.Trainers[trn].MaxRanks) : "") ~ "\n";
				}
			}
			if (classtotal > 0)
			{
				output ~= classnames[type] ~ ":\n";
				output ~= classoutput;
				output ~= "  " ~ classnames[type] ~ " total: " ~ std.string.toString(classtotal) ~ "\n";
			}
		}
		output ~= "total: " ~ std.string.toString(total);
		return output;
	}
	char[] GetName()
	{
		return simple ? "rank counter simple" : "rank counter extended (default)";
	}

	char[] toString()
	{
		return "ARankcounter";
	}

};
