module logprocess.personalstats;

import std.stdio;
//import std.regexp;
import std.file;
import std.string:atoi;
import std.string:join;
import std.date;
import icere.regexp;
import wx.wx;

import logprocess.alogprocessor;
import logprocess.arankcounter;

class PersonalStats : public ALogProcessor
{
protected:
	RegExp remiscinfos, retitle, retime,
		rezodiac1,rezodiac2,rezodiac3,rezodiac4;
		
	uint zodstate = 0;
	d_time zodtime = 0;
			
	char[] Charname;
	char[] Race;
	char[] Sex;
	char[] Profession;
	char[] Title;
	char[] Soulname;
	char[] Soulnumber;
	char[] ZodiacSign;
	char[] Clan;
public:
	this()
	{

	}
	void Create(AtlpCfg cfg)
	{
		this.Charname = cfg.Charname;
		
		remiscinfos = parent.regexps["RaceSexProfession"];
		retitle = parent.regexps["TitleMessage"];
		rezodiac1 = parent.regexps["Zodiac1"];
		rezodiac2 = parent.regexps["Zodiac2"];
		rezodiac3 = parent.regexps["Zodiac3"];
		rezodiac4 = parent.regexps["Zodiac4"];
	}
	void Reset()
	{
		Race = "";
		Sex = "";
		Profession = "";
		Title = "";
		Soulname = "";
		Soulnumber = "";
		ZodiacSign = "";
		Clan = "";
	}
	void ProcessLine(char[] line)
	{
		auto m = retitle.execute(line);
		if (m)
		{
			if (Title != m.group("title")) Title = m.group("title");
		}else
		{
			m = remiscinfos.execute(line);
			if (m)
			{
				Race = m.group("race");
				Sex = m.group("sex");
				Profession = m.group("prof");
				Clan = m.group("clan");
			}
		}
		RegMatch mz;
		/* to find out the zodiac information, we need four lines in short intervals */
		if (zodstate >= 1 && zodstate < 4)
		{
			/* the zodiac "state" is reset if the next line doesn't occur after 5 seconds */
			mz = parent.retime.execute(line);
			/* 
			 * if there is no timestamp, we have no way to find out if the lines
			 * belong to each other, so we have to cancel the action
			 * TODO: we could use an alternative way of finding this out by counting the lines
			 */
			if (!mz) zodstate = 0;
			if ((parent.ArindalTsToDate(mz) - zodtime) > 5000) zodstate = 0;
		}
		switch (zodstate)
		{
		case 0:
			m = rezodiac1.execute(line);
			if (m)
			{
				zodstate = 1;
				mz = parent.retime.execute(line);
				/* save current timestamp for resetting (see above) */
				zodtime = parent.ArindalTsToDate(mz);
			}
			break;
		case 1:
			m = rezodiac2.execute(line);
			if (m)
			{
				zodstate = 2;
				zodtime = parent.ArindalTsToDate(mz);
			}
			break;
		case 2:
			m = rezodiac3.execute(line);
			if (m)
			{
				zodstate = 3;
				zodtime = parent.ArindalTsToDate(mz);
				Soulname = m.group("soulname");
				Soulnumber = m.group("soulno");
			}
			break;
		case 3:
			m = rezodiac4.execute(line);
			if (m)
			{
				zodstate = 4;
				zodtime = 0;
				ZodiacSign = m.group("zodiac");
			}
			break;
		default: break;
		}
		
	}
	char[] GetName()
	{
		return "personal stats";
	}
	char[] GetStats()
	{
		return "\nPersonal Stats\n--------------" ~
		"\nName: " ~ Charname ~
		"\nClan: " ~ Clan ~
		"\nRace: " ~ Race ~
		"\nSex: " ~ Sex ~
		"\nProfession: " ~ Profession ~
		"\nTitle: " ~ Title ~
		"\nSoul: " ~ Soulname ~ " ("~Soulnumber~")" ~
		"\nZodiac: " ~ ZodiacSign;
	}
	void PrintStats()
	{
	}
}