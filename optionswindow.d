module optionswindow;

import std.stdio;
import wx.wx;
import main;

public class OptionsWindow : Frame
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
		ID_RESET_BUTTON,
		ID_STARTTIME_EDIT, ID_ENDTIME_EDIT,
	}

public:
	TextCtrl	StartTime, EndTime;
	CheckBox	RankcounterSimple, Rankcounter,
				Killcounter, Firstkills,
				Personalstats,
				Milestones,
				Fallentos,
				Collisseum,
				Shares;
	
	public this(AFrame parent)
	{
		/* window */
		this.parent = parent;
		super(parent, "Processing Options", Point(10,10), Size(300,300), wxFRAME_TOOL_WINDOW | wxCAPTION | wxSYSTEM_MENU | wxCLOSE_BOX | wxFRAME_FLOAT_ON_PARENT, "procops");
		Wnd = new Window(this, wxID_ANY, Point(10,10), Size(100,100));
		
		EVT_CLOSE(&OnClose);
		
		new StaticBox(Wnd, wxID_ANY, "Processors", Point(10, 10), Size(280, 170));
		
		uint yPos = 30;
		
		RankcounterSimple = new CheckBox(Wnd, -1, "rank counter (simple)", Point(20, yPos));
		RankcounterSimple.Value = true;
		Rankcounter = new CheckBox(Wnd, -1, "rank counter (smart)", Point(160, yPos));
		Rankcounter.Value = false;
		yPos += 20;
		
		Killcounter = new CheckBox(Wnd, -1, "kill counter", Point(20, yPos));
		Killcounter.Value = true;
		Firstkills = new CheckBox(Wnd, -1, "first kills", Point(160, yPos));
		Firstkills.Value = false;
		yPos += 20;
		
		Personalstats = new CheckBox(Wnd, -1, "personal stats", Point(20, yPos));
		Personalstats.Value = false;
		yPos += 20;

		
		Milestones = new CheckBox(Wnd, -1, "milestones", Point(20, yPos));
		Milestones.Value = false;
		yPos += 20;
		

		new Button(Wnd, ID_RESET_BUTTON, "Reset Stats", Point(180, yPos-10));
		EVT_BUTTON(ID_RESET_BUTTON, &parent.OnResetButton);

		Fallentos = new CheckBox(Wnd, -1, "fallen counter", Point(20, yPos));
		Fallentos.Value = false;
		yPos += 20;

		Collisseum = new CheckBox(Wnd, -1, "collisseum fights", Point(20, yPos));
		Collisseum.Value = false;
		yPos += 20;

		Shares = new CheckBox(Wnd, -1, "share stats", Point(20, yPos));
		Shares.Value = false;
		yPos += 20;
		
		yPos += 20;
		new StaticText(Wnd, "start at:", Point(10, yPos));
		StartTime = new TextCtrl(Wnd, ID_STARTTIME_EDIT, "", Point(60, yPos), Size(200, -1));
		EVT_TEXT(ID_STARTTIME_EDIT, &OnStartTimeEdit);
		yPos += 30;
		new StaticText(Wnd, "end at:", Point(10, yPos));
		EndTime = new TextCtrl(Wnd, ID_ENDTIME_EDIT, "", Point(60, yPos), Size(200, -1));
		EVT_TEXT(ID_ENDTIME_EDIT, &OnEndTimeEdit);
		yPos += 30;

	}
	protected void OnClose(Object sender, Event e)
	{
		(cast(CloseEvent)e).Veto();
		parent.Tools.ToggleTool(parent.Cmd.ShowOptions, false);
		parent.OnShowOptions(sender, e);
	}
	protected void OnStartTimeEdit(Object sender, Event e)
	{
		if (parent.ConvertToTime(StartTime.Value) == 0) StartTime.ForegroundColour = Colour.wxRED;
		else StartTime.ForegroundColour = Colour.wxBLACK;
		StartTime.Refresh();
	}
	protected void OnEndTimeEdit(Object sender, Event e)
	{
		if (parent.ConvertToTime(EndTime.Value) == 0) EndTime.ForegroundColour = Colour.wxRED;
		else EndTime.ForegroundColour = Colour.wxBLACK;
		EndTime.Refresh();
	}
	public void DisableAll()
	{
		StartTime.Enabled = false;
		EndTime.Enabled = false;
		RankcounterSimple.Enabled = false;
		Rankcounter.Enabled = false;
		Killcounter.Enabled = false;
		Firstkills.Enabled = false;
		Personalstats.Enabled = false;
		Milestones.Enabled = false;
		Fallentos.Enabled = false;
		Collisseum.Enabled = false;
		Shares.Enabled = false;
	}
	public void EnableAll()
	{
		StartTime.Enabled = true;
		EndTime.Enabled = true;
		RankcounterSimple.Enabled = true;
		Rankcounter.Enabled = true;
		Killcounter.Enabled = true;
		Firstkills.Enabled = true;
		Personalstats.Enabled = true;
		Milestones.Enabled = true;
		Fallentos.Enabled = true;
		Collisseum.Enabled = true;
		Shares.Enabled = true;
	}
	
}