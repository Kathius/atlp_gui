module killswindow;

import std.stdio;
import wx.wx;

import logprocess.killcounter;
import logprocess.fallentos;
import logprocess.collisseum;
import main;

public class KillsWindow : Frame
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
	enum KillsType {Total=0,Solo=1,Group=2,Self=3,Firsts=4,Colli=5};
	
	Grid[KillsType.max+1]	KillsGrid;
	KillCounter 			kc;
	FallenTos 				ft;
	CollisseumFights		co;
	Notebook				Tabs;
	
	public this(AFrame parent)
	{
		/* window */
		this.parent = parent;
		super(parent, "Kills", Point(10,10), Size(630,420), wxFRAME_TOOL_WINDOW | wxCAPTION | wxSYSTEM_MENU | wxCLOSE_BOX | wxFRAME_FLOAT_ON_PARENT, "kills");
		Wnd = new Window(this, wxID_ANY, Point(0,0), Size(630,420));
		Tabs = new Notebook(Wnd, wxID_ANY, Point(0,0), Size(620,390));
		EVT_CLOSE(&OnClose);
		
		/* total, solo, group grids */
		for (auto iType = KillsType.Total; iType<=KillsType.Group; iType++)
		{
			KillsGrid[iType] = new Grid(Tabs, wxID_ANY, Point(10, 10), Size(610, 356));
			KillsGrid[iType].CreateGrid(0, 5);
			KillsGrid[iType].RowLabelSize = 180;
			KillsGrid[iType].SetColSize(0, 80);
			KillsGrid[iType].SetColLabelValue(0, "Total");
			KillsGrid[iType].SetColSize(1, 80);
			KillsGrid[iType].SetColLabelValue(1, "Vanquish");
			KillsGrid[iType].SetColSize(2, 80);
			KillsGrid[iType].SetColLabelValue(2, "Kill");
			KillsGrid[iType].SetColSize(3, 80);
			KillsGrid[iType].SetColLabelValue(3, "Dispatch");
			KillsGrid[iType].SetColSize(4, 80);
			KillsGrid[iType].SetColLabelValue(4, "Slaughter");
			
			KillsGrid[iType].ForceRefresh();
		}
		
		/* first kills grid */
		KillsGrid[KillsType.Firsts] = new Grid(Tabs, wxID_ANY, Point(10, 10), Size(610, 356));
		KillsGrid[KillsType.Firsts].CreateGrid(0, 4);
		KillsGrid[KillsType.Firsts].RowLabelSize = 180;
		KillsGrid[KillsType.Firsts].SetColSize(0, 100);
		KillsGrid[KillsType.Firsts].SetColLabelValue(0, "Vanquish");
		KillsGrid[KillsType.Firsts].SetColSize(1, 100);
		KillsGrid[KillsType.Firsts].SetColLabelValue(1, "Kill");
		KillsGrid[KillsType.Firsts].SetColSize(2, 100);
		KillsGrid[KillsType.Firsts].SetColLabelValue(2, "Dispatch");
		KillsGrid[KillsType.Firsts].SetColSize(3, 100);
		KillsGrid[KillsType.Firsts].SetColLabelValue(3, "Slaughter");
		KillsGrid[KillsType.Firsts].ForceRefresh();

		/* killed by grid */
		KillsGrid[KillsType.Self] = new Grid(Tabs, wxID_ANY, Point(10, 10), Size(610, 356));
		KillsGrid[KillsType.Self].CreateGrid(0, 2);
		KillsGrid[KillsType.Self].RowLabelSize = 200;
		KillsGrid[KillsType.Self].SetColSize(0, 100);
		KillsGrid[KillsType.Self].SetColLabelValue(0, "Deaths");
		KillsGrid[KillsType.Self].SetColSize(1, 100);
		KillsGrid[KillsType.Self].SetColLabelValue(1, "Departs");

		/* collisseum grid */
		KillsGrid[KillsType.Colli] = new Grid(Tabs, wxID_ANY, Point(10, 10), Size(610, 356));
		KillsGrid[KillsType.Colli].CreateGrid(0, 2);
		KillsGrid[KillsType.Colli].RowLabelSize = 200;
		KillsGrid[KillsType.Colli].SetColSize(0, 100);
		KillsGrid[KillsType.Colli].SetColLabelValue(0, "Won");
		KillsGrid[KillsType.Colli].SetColSize(1, 100);
		KillsGrid[KillsType.Colli].SetColLabelValue(1, "Lost");

		
		Tabs.AddPage(KillsGrid[KillsType.Total], "Total");
		Tabs.AddPage(KillsGrid[KillsType.Solo], "Solo");
		Tabs.AddPage(KillsGrid[KillsType.Group], "Group");
		Tabs.AddPage(KillsGrid[KillsType.Self], "Self");
		Tabs.AddPage(KillsGrid[KillsType.Firsts], "First");
		Tabs.AddPage(KillsGrid[KillsType.Colli], "Collisseum");
		
		kc = new KillCounter();
		ft = new FallenTos();
		co = new CollisseumFights();
	}
	protected void OnClose(Object sender, Event e)
	{
		(cast(CloseEvent)e).Veto();
		parent.Tools.ToggleTool(parent.Cmd.ShowKills, false);
		parent.OnShowKills(sender, e);
	}
	
	public void Update()
	{
		Clear();
		auto kills = kc.GetKills();
		for (auto iType = KillsType.Total; iType <= KillsType.Group; iType++)
		{
			KillsGrid[iType].BeginBatch();
			KillsGrid[iType].AppendRows(kills.length+1);
		}
		
		int iMonster = 0;
		int[][] ovtotals = [[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]];
		foreach (Monster, arKills; kills)
		{
			KillsGrid[KillsType.Total].SetRowLabelValue(iMonster, Monster);
			KillsGrid[KillsType.Solo].SetRowLabelValue(iMonster, Monster);
			KillsGrid[KillsType.Group].SetRowLabelValue(iMonster, Monster);
			
			for (auto ikt = KillsType.Solo; ikt <= KillsType.Group; ikt++) for (auto ist=0; ist < 4; ist++)
			{
				auto killentry = (ikt-1)*4+(3-ist);
				ovtotals[ikt][ist+1] += arKills[killentry];
				ovtotals[ikt][0] += arKills[killentry];
				ovtotals[KillsType.Total][ist+1] += arKills[killentry];
				ovtotals[KillsType.Total][0] += arKills[killentry];
			}
			KillsGrid[KillsType.Solo].SetCellValue(iMonster, 0, std.string.toString(arKills[0]+arKills[1]+arKills[2]+arKills[3]));
			KillsGrid[KillsType.Solo].SetCellValue(iMonster, 1, std.string.toString(arKills[3]));
			KillsGrid[KillsType.Solo].SetCellValue(iMonster, 2, std.string.toString(arKills[2]));
			KillsGrid[KillsType.Solo].SetCellValue(iMonster, 3, std.string.toString(arKills[1]));
			KillsGrid[KillsType.Solo].SetCellValue(iMonster, 4, std.string.toString(arKills[0]));
			
			KillsGrid[KillsType.Group].SetCellValue(iMonster, 0, std.string.toString(arKills[4]+arKills[5]+arKills[6]+arKills[7]));
			KillsGrid[KillsType.Group].SetCellValue(iMonster, 1, std.string.toString(arKills[7]));
			KillsGrid[KillsType.Group].SetCellValue(iMonster, 2, std.string.toString(arKills[6]));
			KillsGrid[KillsType.Group].SetCellValue(iMonster, 3, std.string.toString(arKills[5]));
			KillsGrid[KillsType.Group].SetCellValue(iMonster, 4, std.string.toString(arKills[4]));
			
			KillsGrid[KillsType.Total].SetCellValue(iMonster, 0, std.string.toString(
				arKills[0]+arKills[1]+arKills[2]+arKills[3]+arKills[4]+arKills[5]+arKills[6]+arKills[7]));
			KillsGrid[KillsType.Total].SetCellValue(iMonster, 1, std.string.toString(arKills[3]+arKills[7]));
			KillsGrid[KillsType.Total].SetCellValue(iMonster, 2, std.string.toString(arKills[2]+arKills[6]));
			KillsGrid[KillsType.Total].SetCellValue(iMonster, 3, std.string.toString(arKills[1]+arKills[5]));
			KillsGrid[KillsType.Total].SetCellValue(iMonster, 4, std.string.toString(arKills[0]+arKills[4]));
			/* haven't found a better way to make everything readonly so far */
			for (auto iType=KillsType.Total;iType<=KillsType.Group;iType++) for (auto iCol=0;iCol<5;iCol++) KillsGrid[iType].SetReadOnly(iMonster, iCol, true);
			
			iMonster++; 
		}
		/* totals */
		for (auto ikt = KillsType.Total; ikt <= KillsType.Group; ikt++)
		{
			KillsGrid[ikt].SetRowLabelValue(iMonster, "overall");
			for (auto ist=0; ist < 5; ist++)
			{
				KillsGrid[ikt].SetCellValue(iMonster, ist, std.string.toString(ovtotals[ikt][ist]));
			}
		}
		
		/* first time killed */
		auto firstkills = kc.GetKillTimes();
		KillsGrid[KillsType.Firsts].BeginBatch();
		KillsGrid[KillsType.Firsts].AppendRows(firstkills.length);
		iMonster = 0;
		foreach (Monster, arKills; firstkills)
		{
			KillsGrid[KillsType.Firsts].SetRowLabelValue(iMonster, Monster);
			KillsGrid[KillsType.Firsts].SetCellValue(iMonster, 0, arKills[3]);
			KillsGrid[KillsType.Firsts].SetCellValue(iMonster, 1, arKills[2]);
			KillsGrid[KillsType.Firsts].SetCellValue(iMonster, 2, arKills[1]);
			KillsGrid[KillsType.Firsts].SetCellValue(iMonster, 3, arKills[0]);
			for (auto iCol=0;iCol<4;iCol++) KillsGrid[KillsType.Firsts].SetReadOnly(iMonster, iCol, true);
			iMonster++;
		}

		/* deaths */
		auto killedby = ft.GetFallenTos();
		KillsGrid[KillsType.Self].BeginBatch();
		KillsGrid[KillsType.Self].AppendRows(killedby.length+1);
		int[] fallentotals = [0,0];
		iMonster = 0;
		foreach (Monster, Times; killedby)
		{
			KillsGrid[KillsType.Self].SetRowLabelValue(iMonster, Monster);
			KillsGrid[KillsType.Self].SetCellValue(iMonster, 0, std.string.toString(Times[0]));
			KillsGrid[KillsType.Self].SetCellValue(iMonster, 1, std.string.toString(Times[1]));
			fallentotals[0] += Times[0];
			fallentotals[1] += Times[1];
			for (auto iCol=0;iCol<2;iCol++) KillsGrid[KillsType.Self].SetReadOnly(iMonster, iCol, true);
			iMonster++;
		}
		KillsGrid[KillsType.Self].SetRowLabelValue(iMonster, "Totals");
		KillsGrid[KillsType.Self].SetCellValue(iMonster, 0, std.string.toString(fallentotals[0]));
		KillsGrid[KillsType.Self].SetCellValue(iMonster, 1, std.string.toString(fallentotals[1]));

		/* colli */
		auto collistats = co.GetFights();
		KillsGrid[KillsType.Colli].BeginBatch();
		KillsGrid[KillsType.Colli].AppendRows(collistats.length+1);
		int[] collitotals = [0,0];
		iMonster = 0;
		foreach (Monster, Times; collistats)
		{
			KillsGrid[KillsType.Colli].SetRowLabelValue(iMonster, Monster);
			KillsGrid[KillsType.Colli].SetCellValue(iMonster, 0, std.string.toString(Times[0]));
			KillsGrid[KillsType.Colli].SetCellValue(iMonster, 1, std.string.toString(Times[1]));
			collitotals[0] += Times[0];
			collitotals[1] += Times[1];
			for (auto iCol=0;iCol<2;iCol++) KillsGrid[KillsType.Colli].SetReadOnly(iMonster, iCol, true);
			iMonster++;
		}
		KillsGrid[KillsType.Colli].SetRowLabelValue(iMonster, "Totals");
		KillsGrid[KillsType.Colli].SetCellValue(iMonster, 0, std.string.toString(collitotals[0]));
		KillsGrid[KillsType.Colli].SetCellValue(iMonster, 1, std.string.toString(collitotals[1]));

		
		for (auto iType=0;iType<=KillsType.max;iType++) KillsGrid[iType].EndBatch();
	}
	protected void Clear()
	{
		for (auto iType=0;iType<=KillsType.max;iType++)
		{
			if (KillsGrid[iType].NumberRows == 0) continue;
			KillsGrid[iType].DeleteRows(0, KillsGrid[iType].NumberRows);
		}
	}
	public void Reset()
	{
		Clear();
		kc.Reset();
		ft.Reset();
		co.Reset();
	}
}