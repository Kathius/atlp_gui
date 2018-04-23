module main;

import std.stdio;
import wx.wx;
import std.path;
import std.file;
//import std.regexp;
import std.date;
import icere.regexp;

import optionswindow;
import rankwindow;
import pinfowindow;
import killswindow;
import shareswindow;


import logprocess.atextlogcollection;

//import popen;

public class AFrame : Frame
{
	Window		Wnd;			// main window
	ToolBar 	Tools;			// main toolbar
	ComboBox 	CharSelector; 	// combo box for character selection
	TextCtrl 	ArindalRootEdit,
				AtlpLocation,
				AtlpCfgLocation,
				SettingsLocation;
	CheckBox	AutowriteSettings,
				AutocreateAtlpCfg;

	OptionsWindow 		OptionsWnd;
	RankWindow			RankWnd;
	PersonalInfoWindow	InfoWnd;
	KillsWindow			KillsWnd;
	SharesWindow		SharesWnd;

	ATextlogCollection tlc;

	enum Mode {FullScan = 1, PartialScan};
	Mode ScanMode;
	char[] lastchar;

	enum Cmd
	{
		Exit=1,
		ConfigChooseArindalDir, ConfigChooseAtlpLocation, ConfigChooseAtlpCfgLocation,
			ConfigChooseSettingsLocation,
		ProcessLogs,
		ShowOptions,
		ShowRanks, ShowInfo, ShowKills, ShowShares,
	}

	enum
	{
		ID_WINDOW = 1,
		ID_CHAR_DROPDOWN,
		ID_CONFIG_CHOOSE_BUTTON,
		ID_ATLP_CHOOSE_BUTTON,
		ID_ATLPCFG_CHOOSE_BUTTON,
		ID_SETTINGS_CHOOSE_BUTTON,
		ID_TEST_BUTTON,
		ID_ARINDAL_ROOT_EDIT,
	}

	public this(string title, Point pos, Size size)
	{
		/* window */
		super(title, pos, size, wxMINIMIZE_BOX | wxMAXIMIZE_BOX | wxSYSTEM_MENU | wxCAPTION | wxCLOSE_BOX | wxCLIP_CHILDREN);
		icon = new Icon("pngs/logo.png", BitmapType.wxBITMAP_TYPE_PNG);
		Wnd = new Window(this, wxID_ANY, pos, size);

		OptionsWnd = new OptionsWindow(this);

		RankWnd = new RankWindow(this);
		InfoWnd = new PersonalInfoWindow(this);
		KillsWnd = new KillsWindow(this);
		SharesWnd = new SharesWindow(this);

		ScanMode = Mode.PartialScan;
		lastchar = "";

		tlc = new ATextlogCollection();

		/* menu */
		auto FileMenu = new Menu();
		FileMenu.Append(Cmd.Exit, "Ende");
		auto MainMenu = new MenuBar();
		MainMenu.Append(FileMenu, "Datei");

		this.menuBar = MainMenu;

		/* menu events */
		EVT_MENU(Cmd.Exit,	&OnExit);
		EVT_CLOSE(&OnClose);

		/* toolbar */
		auto img = new Image();

		Tools = new ToolBar(Wnd, -1, Point(0,0), Size(450,30));
		CharSelector = new ComboBox(Tools, "", Point(0,0), Size(120,-1), [], ComboBox.wxCB_READONLY);
		Tools.AddControl(CharSelector);

		img.LoadFile("pngs/logo.png");
		img.Rescale(16, 16);
		Tools.AddTool(Cmd.ProcessLogs, "PL", new Bitmap(img), "Process Logs");
		EVT_MENU(Cmd.ProcessLogs, &OnProcessLogs);

		Tools.AddSeparator();

		img.LoadFile("pngs/optionen.png");
		img.Rescale(16, 16);
		Tools.AddTool(Cmd.ShowOptions, "SO", new Bitmap(img), "Show Options", ItemKind.wxITEM_CHECK);
		EVT_MENU(Cmd.ShowOptions, &OnShowOptions);

		Tools.AddSeparator();

		img.LoadFile("pngs/ranks.png");
		img.Rescale(16, 16);
		Tools.AddTool(Cmd.ShowRanks, "SR", new Bitmap(img), "Show Ranks", ItemKind.wxITEM_CHECK);
		EVT_MENU(Cmd.ShowRanks, &OnShowRanks);

		img.LoadFile("pngs/infos.png");
		img.Rescale(16, 16);
		Tools.AddTool(Cmd.ShowInfo, "PI", new Bitmap(img), "Show Personal Info", ItemKind.wxITEM_CHECK);
		EVT_MENU(Cmd.ShowInfo, &OnShowPersonalInfo);

		img.LoadFile("pngs/kills.png");
		img.Rescale(16, 16);
		Tools.AddTool(Cmd.ShowKills, "SK", new Bitmap(img), "Show Kills", ItemKind.wxITEM_CHECK);
		EVT_MENU(Cmd.ShowKills, &OnShowKills);

		img.LoadFile("pngs/shares.png");
		img.Rescale(16, 16);
		Tools.AddTool(Cmd.ShowShares, "Sh", new Bitmap(img), "Show Shares", ItemKind.wxITEM_CHECK);
		EVT_MENU(Cmd.ShowShares, &OnShowShares);
		Tools.Realize();

		//new Button(Wnd, ID_TEST_BUTTON, "Choose...", Point(150, 230));
		//EVT_BUTTON(ID_TEST_BUTTON, &OnTestButton);

		/* Configuration */
		uint yPos = 40;
		new StaticText(Wnd, "Arindal directory:", Point(10, yPos));
		ArindalRootEdit = new TextCtrl(Wnd, ID_ARINDAL_ROOT_EDIT, "", Point(100, yPos-4), Size(200, -1));
		EVT_TEXT(ID_ARINDAL_ROOT_EDIT, &OnArindalRootChange);
		new Button(Wnd, ID_CONFIG_CHOOSE_BUTTON, "Choose...", Point(320, yPos-4));
		EVT_BUTTON(ID_CONFIG_CHOOSE_BUTTON, &OnConfigChooseButton);
		yPos += 30;

		/*
		new StaticText(Wnd, "atlp location:", Point(10, yPos));
		AtlpLocation = new TextCtrl(Wnd, -1, "", Point(100, yPos-4), Size(200, -1));
		new Button(Wnd, ID_ATLP_CHOOSE_BUTTON, "Choose...", Point(320, yPos-4));
		EVT_BUTTON(ID_ATLP_CHOOSE_BUTTON, &OnConfigChooseAtlpButton);
		yPos += 30;
		*/
		new StaticText(Wnd, "atlp cfg file:", Point(10, yPos));
		AtlpCfgLocation = new TextCtrl(Wnd, -1, "trainers.cfg", Point(100, yPos-4), Size(200, -1));
		new Button(Wnd, ID_ATLPCFG_CHOOSE_BUTTON, "Choose...", Point(320, yPos-4));
		EVT_BUTTON(ID_ATLPCFG_CHOOSE_BUTTON, &OnConfigChooseAtlpCfgButton);
		yPos += 30;


		new StaticText(Wnd, "settings file:", Point(10, yPos));
		SettingsLocation = new TextCtrl(Wnd, -1, "settings.conf", Point(100, yPos-4), Size(200, -1));
		new Button(Wnd, ID_SETTINGS_CHOOSE_BUTTON, "Choose...", Point(320, yPos-4));
		EVT_BUTTON(ID_SETTINGS_CHOOSE_BUTTON, &OnConfigChooseSettingsButton);
		yPos += 30;



		AutowriteSettings = new CheckBox(Wnd, -1, "autosave settings on exit", Point(10, yPos));
		AutowriteSettings.Value = true;
		yPos += 20;

		AutocreateAtlpCfg = new CheckBox(Wnd, -1, "autocreate atlp configuration file if needed", Point(10, yPos));
		AutocreateAtlpCfg.Value = true;

		LoadSettings("settings.conf");
	}
	/*
	 * exit
	 */
	public void OnExit(Object sender, Event e)
	{
		Close(true);
	}
	public void OnClose(Object sender, Event e)
	{
		if (AutowriteSettings.Value) WriteSettings();
		Destroy();
	}
	/*
	 * basic configuration
	 */
	public void OnConfigChooseButton(Object sender, Event e)
	{
		auto dlg = new DirDialog(Wnd, "Please choose the Arindal root", ArindalRootEdit.Value);
		if (dlg.ShowModal() != wxID_OK) return;

		ArindalRootEdit.Value = dlg.Path;
		ArindalRootEdit.ForegroundColour = Colour.wxBLACK;
		if (!LoadCharactersFromPath()) ArindalRootEdit.ForegroundColour = Colour.wxRED;
	}

	public void OnConfigChooseAtlpButton(Object sender, Event e)
	{
		FileDialog dlg;
		version (Win32)
		{
			dlg = new FileDialog(Wnd, "Please choose the atlp location", getDirName(AtlpLocation.Value), "atlp.exe", "atlp.exe|atlp.exe|Ausführbare Dateien (*.exe)|*.exe", FileDialog.wxOPEN | FileDialog.wxFILE_MUST_EXIST);
		}else
		{
			dlg = new FileDialog(Wnd, "Please choose the atlp location", getDirName(AtlpLocation.Value), "atlp", "atlp", FileDialog.wxOPEN | FileDialog.wxFILE_MUST_EXIST);
		}
		if (dlg.ShowModal() == wxID_OK)
		{
			AtlpLocation.Value = dlg.Path;
		}
	}
	public void OnConfigChooseAtlpCfgButton(Object sender, Event e)
	{
		FileDialog dlg;
		dlg = new FileDialog(Wnd, "Please choose the atlp configuration location", getDirName(AtlpCfgLocation.Value), "atlp.conf", "atlp.conf|atlp.conf", FileDialog.wxOPEN | FileDialog.wxFILE_MUST_EXIST);
		if (dlg.ShowModal() == wxID_OK)
		{
			AtlpCfgLocation.Value = dlg.Path;
		}
	}
	public void OnConfigChooseSettingsButton(Object sender, Event e)
	{
		FileDialog dlg;
		dlg = new FileDialog(Wnd, "Please choose the settings location", getDirName(SettingsLocation.Value), "atlp_gui.conf", "atlp_gui Settings file|*.conf", FileDialog.wxSAVE);
		if (dlg.ShowModal() == wxID_OK)
		{
			SettingsLocation.Value = dlg.Path;
		}
	}

	/*
	 * subwindows
	 */

	protected void ResetStats()
	{
		RankWnd.Reset();
		InfoWnd.Reset();
		KillsWnd.Reset();
		SharesWnd.Reset();
	}
	protected void ResetAll()
	{
		ResetStats();
		OptionsWnd.StartTime.Value = "";
		OptionsWnd.EndTime.Value = "";
		OptionsWnd.EnableAll();
		ScanMode = Mode.PartialScan;
	}

	protected void OnProcessLogs(Object sender, Event e)
	{
		ProgressDialog dlg;
		void OnStartProcessing(uint nFiles)
		{
			 dlg = new ProgressDialog("Processing files...", "", nFiles, this,
					 ProgressDialog.wxPD_CAN_ABORT |
					 ProgressDialog.wxPD_APP_MODAL |
					 ProgressDialog.wxPD_AUTO_HIDE |
					 0x0020 |
					 ProgressDialog.wxPD_APP_MODAL |
					 ProgressDialog.wxPD_REMAINING_TIME);
			 dlg.SetSize(Size(500,160));
		}
		bool OnUpdate(uint iFile, char[] Filename)
		{
			return dlg.Update(iFile, Filename);
		}
		void OnEndProcessing(d_time EndTime)
		{
			if (EndTime == 0) return;
			if (ScanMode == Mode.PartialScan) return;
			OptionsWnd.StartTime.Value = FormatDate(EndTime);
			OptionsWnd.EndTime.Value = "";
		}

		AtlpCfg cfg;
		cfg.Path = ArindalRootEdit.Value;
		cfg.Charname = CharSelector.Value;
		cfg.lang = AtlpLanguage.de;

		if (ScanMode == Mode.FullScan)
		{
			if (lastchar != CharSelector.Value) ResetAll();
		} /* no else! we need the next if... */
		if (ScanMode == Mode.PartialScan)
		{
			ResetStats();
			if (OptionsWnd.StartTime.Value == "" && OptionsWnd.EndTime.Value == "")
			{
				ScanMode = Mode.FullScan;
				OptionsWnd.DisableAll();
			}
		}
		lastchar = CharSelector.Value;
		try
		{

			tlc.Init(cfg);
			OptionsWnd.Refresh();
			if (OptionsWnd.RankcounterSimple.IsChecked) tlc.AttachLoglineProcessor(RankWnd.rcs);
			if (OptionsWnd.Rankcounter.IsChecked) tlc.AttachLoglineProcessor(RankWnd.rc);
			if (OptionsWnd.Personalstats.IsChecked)
			{
				tlc.AttachLoglineProcessor(InfoWnd.ps);
				tlc.AttachLoglineProcessor(InfoWnd.lt);
			}
			if (OptionsWnd.Killcounter.IsChecked) tlc.AttachLoglineProcessor(KillsWnd.kc);
			if (OptionsWnd.Fallentos.IsChecked) tlc.AttachLoglineProcessor(KillsWnd.ft);
			if (OptionsWnd.Collisseum.IsChecked) tlc.AttachLoglineProcessor(KillsWnd.co);
			if (OptionsWnd.Shares.IsChecked) tlc.AttachLoglineProcessor(SharesWnd.sc);

			tlc.ProcessFiles(ConvertToTime(OptionsWnd.StartTime.Value), ConvertToTime(OptionsWnd.EndTime.Value),
				&OnStartProcessing, &OnUpdate, &OnEndProcessing);

			dlg.Hide();

			tlc.DetachAllProcessors();

			RankWnd.Update();
			InfoWnd.Update();
			KillsWnd.Update();
			SharesWnd.Update();
		}catch (ExecuteTimeException e)
		{
			MessageBox("Couldn't process files: " ~ e.msg ~ " (" ~ std.string.toString(e.code) ~ ")");
		}catch (Exception e)
		{
			MessageBox("Couldn't process files: " ~ e.msg);
		}
	}
	public d_time ConvertToTime(char[] strDate)
	{
		auto regdate_de = new RegExp(r"^(?P<day>\d?\d)\.(?P<month>\d?\d).(?P<year>(?:\d\d)?(?:\d\d))\s+(?:(?P<hour>\d?\d):(?P<minute>\d\d):(?P<second>\d\d))$");
		auto regdate_en = new RegExp(r"^(?P<month>\d?\d)[-/](?P<day>\d?\d)[-/](?P<year>(?:\d\d)?(?:\d\d))\s+(?:(?P<hour>\d\d):(?P<minute>\d\d):(?P<second>\d\d))$");

		auto m = regdate_de.execute(strDate);
		if (!m)
		{
			m = regdate_en.execute(strDate);
			if (!m) return 0;
		}
		return std.date.parse(
			(m.group("year").length == 2 ? "20" : "") ~ m.group("year") ~ "-" ~ m.group("month") ~ "-" ~ m.group("day") ~ " " ~
			m.group("hour") ~ ":" ~ m.group("minute") ~ ":" ~ m.group("second"));
	}
	protected char[] FormatDate(d_time Time)
	{
		auto time = new Date();
		time.parse(std.date.toString(Time));
		return std.string.format("%d.%d.%d %02d:%02d:%02d",
			time.day, time.month, time.year, time.hour, time.minute, time.second);
	}


	public void OnArindalRootChange(Object sender, Event e)
	{
		ArindalRootEdit.ForegroundColour = Colour.wxBLACK;
		if (!LoadCharactersFromPath()) ArindalRootEdit.ForegroundColour = Colour.wxRED;
		ArindalRootEdit.Refresh();
	}

	/*
	 * toolbar
	 */
	public void OnShowOptions(Object sender, Event e)
	{
		OptionsWnd.Show(Tools.GetToolState(Cmd.ShowOptions));
	}
	public void OnShowRanks(Object sender, Event e)
	{
		RankWnd.Show(Tools.GetToolState(Cmd.ShowRanks));
	}
	public void OnShowPersonalInfo(Object sender, Event e)
	{
		InfoWnd.Show(Tools.GetToolState(Cmd.ShowInfo));
	}
	public void OnShowKills(Object sender, Event e)
	{
		KillsWnd.Show(Tools.GetToolState(Cmd.ShowKills));
	}
	public void OnShowShares(Object sender, Event e)
	{
		SharesWnd.Show(Tools.GetToolState(Cmd.ShowShares));
	}

	public void OnResetButton(Object sender, Event e)
	{
		ResetAll();
	}

	/*
	 * load / save
	 */

	protected bool LoadCharactersFromPath()
	{
		CharSelector.Clear();
		if (!exists(ArindalRootEdit.Value ~ "/data/Text Logs")) return false;
		if (!isdir(ArindalRootEdit.Value ~ "/data/Text Logs")) return false;
		auto dirents = listdir(ArindalRootEdit.Value ~ "/data/Text Logs");
		foreach (dirent; dirents)
		{
			if (!IsCharacterDir(ArindalRootEdit.Value ~ "/data/Text Logs/" ~ dirent)) continue;
			CharSelector.Append(dirent);
		}
		CharSelector.SetSelection(0);
		return true;
	}

	protected bool IsCharacterDir(char[] dirname)
	{
		if (!exists(dirname)) return false;
		if (!isdir(dirname)) return false;
		return true;
	}

	protected void WriteSettings()
	{
		try
		{
			std.file.write(SettingsLocation.Value,
				"autosave = " ~ std.string.toString(AutowriteSettings.Value) ~
				"\nautocreate_atlp_cfg = "  ~ std.string.toString(AutocreateAtlpCfg.Value) ~
				"\narindal_root = " ~ ArindalRootEdit.Value ~
				//"\natlp_path = " ~ AtlpLocation.Value ~
				"\natlpcfg_path = " ~ AtlpCfgLocation.Value ~
				"\nlast_character = " ~ CharSelector.Value ~

				"\nposx = " ~ std.string.toString(Position.X) ~
				"\nposy = " ~ std.string.toString(Position.Y) ~
				"\nrcposx = " ~ std.string.toString(RankWnd.Position.X) ~
				"\nrcposy = " ~ std.string.toString(RankWnd.Position.Y) ~
				"\nrcopen = " ~ std.string.toString(Tools.GetToolState(Cmd.ShowRanks)) ~

				"\nRankcounterSimple = " ~ std.string.toString(OptionsWnd.RankcounterSimple.Value) ~
				"\nRankcounter = " ~ std.string.toString(OptionsWnd.Rankcounter.Value) ~
				"\nKillcounter = " ~ std.string.toString(OptionsWnd.Killcounter.Value) ~
				"\nFirstkills = " ~ std.string.toString(OptionsWnd.Firstkills.Value) ~
				"\nPersonalstats = " ~ std.string.toString(OptionsWnd.Personalstats.Value) ~
				"\nMilestones = " ~ std.string.toString(OptionsWnd.Milestones.Value) ~
				"\nFallentos = " ~ std.string.toString(OptionsWnd.Fallentos.Value) ~
				"\nCollisseum = " ~ std.string.toString(OptionsWnd.Collisseum.Value) ~
				"\nShares = " ~ std.string.toString(OptionsWnd.Shares.Value)
			);
		}catch (Exception e)
		{
			//MessageBox("Couldn't write configuration to file \"" ~ SettingsLocation.Value ~ "\"");
			MessageBox(e.msg);
		}
	}
	protected void LoadSettings(char[] filename)
	{
		if (!exists(filename)) return;
		char[] lastchar;
		auto reConfline = new RegExp(r"^(?P<param>[^=]+)=(?P<value>.+)$");
		auto reLineending = new RegExp(r"(?:\r?\n)|\r");
		auto content = reLineending.split(cast(char[])read(filename));
		foreach (line; content)
		{
			auto m = reConfline.execute(line);
			if (!m) continue;
			auto value = std.string.strip(m.group("value"));
			switch(std.string.strip(m.group("param")))
			{
			case "posx":
				auto p = Position;
				p.X = std.string.atoi(value);
				Position = p;
				break;
			case "posy":
				Point p = Position;
				p.Y = std.string.atoi(value);
				Position = p;
				break;
			case "rcposx":
				Point p = RankWnd.Position;
				p.X = std.string.atoi(value);
				RankWnd.Position = p;
				break;
			case "rcposy":
				auto p = RankWnd.Position;
				p.Y = std.string.atoi(value);
				RankWnd.Position = p;
				break;
			case "rcopen":
				Tools.ToggleTool(Cmd.ShowRanks, value == "true");
				RankWnd.Show(Tools.GetToolState(Cmd.ShowRanks));
				break;
			case "autosave":
				AutowriteSettings.Value = value == "true" ? true : false;
				break;
			case "autocreate_atlp_cfg":
				AutocreateAtlpCfg.Value = value == "true" ? true : false;
				break;
			case "arindal_root":
				ArindalRootEdit.Value = value;
				break;
			case "atlpcfg_path":
				AtlpCfgLocation.Value = value;
				break;
			case "last_character":
				lastchar = value;
				break;
			case "RankcounterSimple":
				OptionsWnd.RankcounterSimple.Value = value == "true" ? true : false;
				break;
			case "Rankcounter":
				OptionsWnd.Rankcounter.Value = value == "true" ? true : false;
				break;
			case "Killcounter":
				OptionsWnd.Killcounter.Value = value == "true" ? true : false;
				break;
			case "Firstkills":
				OptionsWnd.Firstkills.Value = value == "true" ? true : false;
				break;
			case "Personalstats":
				OptionsWnd.Personalstats.Value = value == "true" ? true : false;
				break;
			case "Milestones":
				OptionsWnd.Milestones.Value = value == "true" ? true : false;
				break;
			case "Fallentos":
				OptionsWnd.Fallentos.Value = value == "true" ? true : false;
				break;
			case "Collisseum":
				OptionsWnd.Collisseum.Value = value == "true" ? true : false;
				break;
			case "Shares":
				OptionsWnd.Shares.Value = value == "true" ? true : false;
				break;
			default: break;
			}
		}
		SettingsLocation.Value = filename;
		LoadCharactersFromPath();
		CharSelector.Value = lastchar;
	}

	public void OnTestButton(Object sender, Event e)
	{
		//MessageBox(FetchAtlp());
	}
}

public class AtlpGui : App
{
	public override bool OnInit()
	{
		AFrame frame = new AFrame(
			"Arindal Text Log Processor Graphical User Interface",
			Point(50,50),
			Size(450,340));
		frame.Show(true);

		return true;
	}
	static void Main()
	{
		AtlpGui app = new AtlpGui();
		try
		{
			app.Run();
		}catch (Exception e) MessageBox(e.msg);
	}
}

int main(char[][] argv)
{
	AtlpGui.Main();
	return 0;
}
