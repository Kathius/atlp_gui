module logprocess.alogprocessor;

public import logprocess.atextlogcollection;
import std.stdio;
import logprocess.regexps;

class ALogProcessor
{
protected:
	AtlpCfg cfg;
	bool bInit=false;
public:
	ATextlogCollection parent;
public:
	int iTest;
	this()
	{
	}
	void OnOpenLogFile()
	{
	}
	void OnCloseLogFile()
	{
	}
	void ProcessLine(char[] content)
	{
	}
	void Create(AtlpCfg cfg)
	{
		this.cfg = cfg;
	}
	char[] toString()
	{
		return "ALogProcessor";
	}
	char[] GetName()
	{
		return "<experimental>";
	}
	void PrintStats()
	{
		writefln(GetStats());
	}
	char[] GetStats()
	{
		return "";
	}
	public void Reset()
	{
	}
};