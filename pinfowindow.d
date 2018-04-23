module pinfowindow;

import std.stdio;
import wx.wx;

import logprocess.personalstats;
import logprocess.logintime;
import main;

public class PersonalInfoWindow : Frame
{
	Window		Wnd;			// window
	AFrame		parent;

	enum Cmd
	{
		Close=1,
	}

	enum
	{
		ID_WINDOW = 1,
	}

public:
	TextCtrl		InfoEdit;
	PersonalStats 	ps;
	LoginTime 		lt;

	public this(AFrame parent)
	{
		/* window */
		this.parent = parent;
		super(parent, "Personal Information", Point(10,10), Size(300,300), wxFRAME_TOOL_WINDOW | wxCAPTION | wxSYSTEM_MENU | wxCLOSE_BOX | wxFRAME_FLOAT_ON_PARENT, "personal info");
		Wnd = new Window(this, wxID_ANY, Point(10,10), Size(100,100));
		EVT_CLOSE(&OnClose);

		InfoEdit = new TextCtrl(Wnd, -1, "", Point(10, 10), Size(280, 256), TextCtrl.wxTE_MULTILINE | TextCtrl.wxTE_READONLY);

		ps = new PersonalStats();
		lt = new LoginTime();
	}
	protected void OnClose(Object sender, Event e)
	{
		(cast(CloseEvent)e).Veto();
		parent.Tools.ToggleTool(parent.Cmd.ShowInfo, false);
		parent.OnShowPersonalInfo(sender, e);
	}
	public void Update()
	{
		InfoEdit.Value = ps.GetStats() ~ "\n" ~ lt.GetStats();
	}
	public void Reset()
	{
		ps.Reset();
		lt.Reset();
		InfoEdit.Value = "";
	}
}
