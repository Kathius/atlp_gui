module shareswindow;

import std.stdio;
import wx.wx;

import logprocess.shares;
import main;

public class SharesWindow : Frame
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
	
	Grid	SharesGrid;
	Shares	sc;
	uint	lastsort = -1;
	bool	rev = false;
	
	public this(AFrame parent)
	{
		/* window */
		this.parent = parent;
		super(parent, "Shares", Point(10,10), Size(630,420), wxFRAME_TOOL_WINDOW | wxCAPTION | wxSYSTEM_MENU | wxCLOSE_BOX | wxFRAME_FLOAT_ON_PARENT, "shares");
		Wnd = new Window(this, wxID_ANY, Point(0,0), Size(630,420));
		EVT_CLOSE(&OnClose);
		
		/* total, solo, group grids */
		SharesGrid = new Grid(Wnd, wxID_ANY, Point(10, 10), Size(610, 356));
		SharesGrid.CreateGrid(0, 3);
		SharesGrid.RowLabelSize = 180;
		SharesGrid.SetColSize(0, 80);
		SharesGrid.SetColLabelValue(0, "Shares");
		SharesGrid.SetColSize(1, 80);
		SharesGrid.SetColLabelValue(1, "Backshares");
		SharesGrid.SetColSize(2, 80);
		SharesGrid.SetColLabelValue(2, "Permanent Shares");
			
		SharesGrid.ForceRefresh();
		
		EVT_GRID_LABEL_LEFT_CLICK(&OnLabelClick);
		
		sc = new Shares();
	}
	char[][] selectionSort(T)(T[char[]] array, bool delegate(T, T) equal)
	{
		char[] temp;
		auto keys = array.keys;
		for(int i = 0; i < keys.length; ++i)
		{
			int min = i;
			for(int j = i + 1; j < keys.length; ++j)
			{
				if (equal(array[keys[j]], array[keys[min]]))
					min = j;
			}
			temp = keys[i];
			keys[i] = keys[min];
			keys[min] = temp;
		}
		return keys;
	}
	protected void OnLabelClick(Object sender, Event e)
	{
		auto col = (cast(GridEvent)e).Col;
		char[][] sorted;
		auto shares = sc.GetShareTimes();
		if (col >= 0)
		{
			bool SortShares(long[] a, long[] b)
			{
				return a[0] < b[0];
			}
			bool SortBackShares(long[] a, long[] b)
			{
				return a[1] < b[1];
			}
			bool SortPermaShares(long[] a, long[] b)
			{
				return a[2] < b[2];
			}
			
			switch(col)
			{
			case 0:
				sorted = selectionSort!(long[])(shares, &SortShares);
				break;
			case 1:
				sorted = selectionSort!(long[])(shares, &SortBackShares);
				break;
			case 2:
				sorted = selectionSort!(long[])(shares, &SortPermaShares);
				break;
			default:break;
			}
		}else if ((cast(GridEvent)e).Row == -1) sorted = shares.keys.sort;
		else return;
		
		if (lastsort == col && !rev) sorted.reverse;
		rev = !rev;
		lastsort = col;
		
		Clear();

		SharesGrid.BeginBatch();
		SharesGrid.AppendRows(shares.length);

		//uint iRow = 0;
		
		foreach (iRow, Player; sorted)
		{
			auto times = shares[Player];
			SharesGrid.SetRowLabelValue(iRow, Player);
			
			SharesGrid.SetCellValue(iRow, 0, sc.GetTimeString(times[0]));
			SharesGrid.SetCellValue(iRow, 1, sc.GetTimeString(times[1]));
			SharesGrid.SetCellValue(iRow, 2, sc.GetTimeString(times[2]));
			/* haven't found a better way to make everything readonly so far */
			for (auto i=0;i<3;i++) SharesGrid.SetReadOnly(iRow, i);
		
			//iRow++; 
		}
		SharesGrid.EndBatch();

	}
	protected void OnClose(Object sender, Event e)
	{
		(cast(CloseEvent)e).Veto();
		parent.Tools.ToggleTool(parent.Cmd.ShowShares, false);
		parent.OnShowShares(sender, e);
	}
	public void Update()
	{
		Clear();
		auto shares = sc.GetShares();

		SharesGrid.BeginBatch();
		SharesGrid.AppendRows(shares.length);
		
		uint iRow = 0;
		
		foreach (Player; shares.keys.sort)
		{
			SharesGrid.SetRowLabelValue(iRow, Player);
			
			SharesGrid.SetCellValue(iRow, 0, shares[Player][0]);
			SharesGrid.SetCellValue(iRow, 1, shares[Player][1]);
			SharesGrid.SetCellValue(iRow, 2, shares[Player][2]);
			/* haven't found a better way to make everything readonly so far */
			for (auto i=0;i<3;i++) SharesGrid.SetReadOnly(iRow, i);
		
			iRow++; 
		}

		SharesGrid.EndBatch();
		lastsort = -1;
		rev = false;
	}
	protected void Clear()
	{
		if (SharesGrid.NumberRows == 0) return;
		SharesGrid.DeleteRows(0, SharesGrid.NumberRows);
	}
	public void Reset()
	{
		Clear();
		sc.Reset();
	}
}