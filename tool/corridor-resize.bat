@powershell "$THISFILE=\"%~f0\"; $PSCODE=[scriptblock]::create((Get-Content $THISFILE | Where-Object {$_.readcount -gt 1}) -join \"`n\"); & $PSCODE %*" & goto:eof
param (
	[string]$TITLE = "pj-corridor.net",
	[int]$W = 800,
	[int]$H = 600
)

Add-Type @"
using System;
using System.Runtime.InteropServices;

public struct RECT
{
	public int L;
	public int T;
	public int R;
	public int B;
}

public class WinAPI
{
	[DllImport("user32.dll")]
	public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
	[DllImport("user32.dll")]
	public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
}
"@

function Resize-Window {
	param (
		$in_handle,
		[int]$in_width,
		[int]$in_height
	)
	$rc = New-Object RECT
	[WinAPI]::GetWindowRect($in_handle, [ref]$rc) > $null
	[WinAPI]::MoveWindow($in_handle, $rc.L, $rc.T, $in_width, $in_height, $true) > $null
}

$psArr = Get-Process | Where-Object { $_.MainWindowTitle -like "*$TITLE*" }

if ($psArr.Count -gt 0) {
	Resize-Window $psArr[0].MainWindowHandle $W $H;
} else {
	Write-Host "not found : $TITLE"
}
