@powershell "$THISFILE=\"%~f0\"; $PSCODE=[scriptblock]::create((Get-Content $THISFILE | Where-Object {$_.readcount -gt 1}) -join \"`n\"); & $PSCODE %*" & goto:eof

param([string[]]$args)

$OPTION = @{}
for ($i = 0; $i -lt $args.Length; $i++) {
	if ($args[$i] -match '^-(.*)') {
		$OPTION[$matches[1]] = $args[++$i]
	}
}

# -t : target application
if ($OPTION.ContainsKey('t')) {
	Set-Variable -Name TARGETAPP -Value "$($OPTION['t'])" -Option Constant
} else {
	Set-Variable -Name TARGETAPP -Value 'chrome' -Option Constant
}

# -r : resize option for imagemagick
if ($OPTION.ContainsKey('r')) {
	Set-Variable -Name RESIZE -Value "-resize $($OPTION['r'])" -Option Constant
	# Write-Host "resize to $($OPTION['r'])"
} else {
	Set-Variable -Name RESIZE -Value '-resize 100%' -Option Constant
}

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
Set-Variable -Name IMAGEMAGICK -Value 'C:\Program Files\ImageMagick-7.1.1-Q16-HDRI\magick.exe' -Option Constant

### 0. settings ###

Set-Variable -Name PNG_PREFIX -Value 'screenshot' -Option Constant
Set-Variable -Name BROWSERUI_HEIGHT -Value 120 -Option Constant

### 1. find $TARGETAPP window ###

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
$screenBmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
# Write-Host "W:$($bounds.Width), H:$($bounds.Height)"

$graphics = [System.Drawing.Graphics]::FromImage($screenBmp)
$graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
[System.Windows.Forms.Clipboard]::SetImage($screenBmp)

### 3. crop '2' using '1' ###

[WINDOWS_API_RECT] $windowRect = New-Object WINDOWS_API_RECT
$res = [WINDOWS_API]::GetWindowRect($process.MainWindowHandle, [ref] $windowRect)
# Write-Host "R:$($windowRect.R), T:$($windowRect.T), L:$($windowRect.L), B:$($windowRect.B)"

[WINDOWS_API_RECT] $clientRect = New-Object WINDOWS_API_RECT
$res = [WINDOWS_API]::GetClientRect($process.MainWindowHandle, [ref] $clientRect)
# Write-Host "R:$($clientRect.R), T:$($clientRect.T), L:$($clientRect.L), B:$($clientRect.B)"

$marginX = $windowRect.R - $windowRect.L - $clientRect.R
$marginY = $windowRect.B - $windowRect.T - $clientRect.B

$targetRect = New-Object System.Drawing.Rectangle(
	($windowRect.L + $marginX / 2),
	($windowRect.T + $BROWSERUI_HEIGHT),
	($windowRect.R - $windowRect.L - $marginX),
	($windowRect.B - $windowRect.T - $marginY - $BROWSERUI_HEIGHT)
)

$index = 0

do {
	$savePath = Join-Path -Path $FILEPATH -ChildPath "$($PNG_PREFIX)-$(('{0:D3}' -f $index)).png"
	$index++
} while (Test-Path $savePath)

$targetBmp = $screenBmp.Clone($targetRect, $screenBmp.PixelFormat)
$targetBmp.Save($savePath, [System.Drawing.Imaging.ImageFormat]::Png)
Start-Process $IMAGEMAGICK -ArgumentList $savePath, '-colors 256', '-depth 8', $RESIZE, $savePath -NoNewWindow -Wait

$graphics.Dispose()
$screenBmp.Dispose()
$targetBmp.Dispose()
