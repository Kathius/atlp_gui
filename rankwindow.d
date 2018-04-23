module rankwindow;

import std.stdio;
import wx.wx;
import main;

import logprocess.arankcounter;


public class RankWindow : Frame
{
	Window		Wnd;			// window
	AFrame		parent;
	Notebook	Tabs;
	
	enum Cmd
	{
		Close=1,
	}
	
	enum 
	{
		ID_WINDOW = 1,
	}

public:
	TextCtrl	RanksEdit, RanksEditAdv;
	ARankCounter rc, rcs;
	
	public this(AFrame parent)
	{
		/* window */
		this.parent = parent;
		super(parent, "Ranks", Point(10,10), Size(300,300), wxFRAME_TOOL_WINDOW | wxCAPTION | wxSYSTEM_MENU | wxCLOSE_BOX | wxFRAME_FLOAT_ON_PARENT, "ranks");
		Wnd = new Window(this, wxID_ANY, Point(10,10), Size(300,300));
		EVT_CLOSE(&OnClose);
		
		Tabs = new Notebook(Wnd, wxID_ANY, Point(0,0), Size(290,280));
		EVT_CLOSE(&OnClose);
		
		RanksEdit = new TextCtrl(Tabs, -1, "", Point(10, 10), Size(270, 256), TextCtrl.wxTE_MULTILINE | TextCtrl.wxTE_READONLY);
		RanksEditAdv = new TextCtrl(Tabs, -1, "", Point(10, 10), Size(270, 256), TextCtrl.wxTE_MULTILINE | TextCtrl.wxTE_READONLY);
		
		Tabs.AddPage(RanksEdit, "Simple");
		Tabs.AddPage(RanksEditAdv, "Advanced");
		
		rc = new ARankCounter();
		rcs = new ARankCounter(true);
	}
	protected void OnClose(Object sender, Event e)
	{
		(cast(CloseEvent)e).Veto();
		parent.Tools.ToggleTool(parent.Cmd.ShowRanks, false);
		parent.OnShowRanks(sender, e);
	}
	public void Update()
	{
		RanksEdit.Value = rcs.GetStats();
		RanksEditAdv.Value = rc.GetStats();
	}
	public void Reset()
	{
		rc.Reset();
		rcs.Reset();
		RanksEdit.Value = "";
		RanksEditAdv.Value = "";
	}
}