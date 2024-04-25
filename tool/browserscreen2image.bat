@powershell "$THISFILE=\"%~f0\"; $PSCODE=[scriptblock]::create((Get-Content $THISFILE | Where-Object {$_.readcount -gt 1}) -join \"`n\"); & $PSCODE" & goto:eof

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
add-type -AssemblyName microsoft.VisualBasic

Add-Type @"
	using System;
	using System.Runtime.InteropServices;
	public struct WINDOWS_API_RECT {
		public int L;
		public int T;
		public int R;
		public int B;
	}
	public class WINDOWS_API {
		[DllImport("user32.dll")]
		public static extern bool IsIconic(IntPtr hWnd);
		[DllImport("user32.dll")]
		public static extern bool GetWindowRect(IntPtr hWnd, out WINDOWS_API_RECT lpRect);
		[DllImport("user32.dll")]
		public static extern bool GetClientRect(IntPtr hWnd, out WINDOWS_API_RECT lpRect);
		[DllImport("user32.dll")]
		public static extern bool ClientToScreen(IntPtr hWnd, ref WINDOWS_API_RECT lpPoint);
	}
"@

Set-Variable -Name FILEPATH -Value ([System.Environment]::GetFolderPath('Desktop')) -Option Constant
Set-Variable -Name IMAGEMAGICK -Value 'C:\Program Files\ImageMagick-7.1.1-Q16-HDRI\convert.exe' -Option Constant

### 0. settings ###

Set-Variable -Name FILENAME -Value 'screenshot.png' -Option Constant
Set-Variable -Name TARGETAPP -Value 'chrome' -Option Constant
Set-Variable -Name START_Y -Value 120 -Option Constant

### 1. find chrome window ###

$ps = Get-Process -Name $TARGETAPP -ErrorAction SilentlyContinue
if ($null -eq $ps) {
	Write-Host "error : can not find $($TARGETAPP)"
	exit
}
$found = $false
foreach($process in $ps) {
	if ($process.MainWindowHandle -eq 0)  {
		continue
	}
	if (![WINDOWS_API]::IsIconic($process.MainWindowHandle)) {
		$found = $true
		[Microsoft.VisualBasic.Interaction]::AppActivate($process.ID)
		break
	}
}
if (!$found) {
	Write-Host "error : $($TARGETAPP) is minimized"
	exit
}

### 2. copy whole primary screen to $screen ###

$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$screen = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
# Write-Host "W:$($bounds.Width), H:$($bounds.Height)"

$graphics = [System.Drawing.Graphics]::FromImage($screen)
$graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
[System.Windows.Forms.Clipboard]::SetImage($screen)

### 3. crop '2' using '1' ###

[WINDOWS_API_RECT] $windowRect = New-Object WINDOWS_API_RECT
[WINDOWS_API]::GetWindowRect($process.MainWindowHandle, [ref] $windowRect)

[WINDOWS_API_RECT] $clientRect = New-Object WINDOWS_API_RECT
[WINDOWS_API]::GetClientRect($process.MainWindowHandle, [ref] $clientRect)

$marginX = $windowRect.R - $windowRect.L - $clientRect.R
$marginY = $windowRect.B - $windowRect.T - $clientRect.B

$browserRect = New-Object System.Drawing.Rectangle(
	($windowRect.L + $marginX / 2),
	($windowRect.T + $START_Y),
	($windowRect.R - $windowRect.L - $marginX),
	($windowRect.B - $windowRect.T - $marginY - $START_Y)
)

$savePath = Join-Path -Path $FILEPATH -ChildPath $FILENAME
$browserPane = $screen.Clone($browserRect, $screen.PixelFormat)
$browserPane.Save($savePath, [System.Drawing.Imaging.ImageFormat]::Png)
Start-Process $IMAGEMAGICK -ArgumentList $savePath, '-colors 256', '-depth 8', $savePath -NoNewWindow -Wait

$graphics.Dispose()
$screen.Dispose()
$browserPane.Dispose()
