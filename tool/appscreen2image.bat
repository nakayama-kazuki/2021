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

# -ml, -mt, -mr, mb : margin left, top, right, bottom
Set-Variable -Name DEFAULT_MARGIN -Value 8 -Option Constant
if ($OPTION.ContainsKey('ml')) {
	Set-Variable -Name WIN_MARGIN_L -Value $OPTION['ml'] -Option Constant
} else {
	Set-Variable -Name WIN_MARGIN_L -Value $DEFAULT_MARGIN -Option Constant
}
if ($OPTION.ContainsKey('mt')) {
	Set-Variable -Name WIN_MARGIN_T -Value $OPTION['mt'] -Option Constant
} else {
	Set-Variable -Name WIN_MARGIN_T -Value 0 -Option Constant
}
if ($OPTION.ContainsKey('mr')) {
	Set-Variable -Name WIN_MARGIN_R -Value $OPTION['mr'] -Option Constant
} else {
	Set-Variable -Name WIN_MARGIN_R -Value $DEFAULT_MARGIN -Option Constant
}
if ($OPTION.ContainsKey('mb')) {
	Set-Variable -Name WIN_MARGIN_B -Value $OPTION['mb'] -Option Constant
} else {
	Set-Variable -Name WIN_MARGIN_B -Value $DEFAULT_MARGIN -Option Constant
}

# -tr : trim option for imagemagick
if ($OPTION.ContainsKey('tr')) {
	Set-Variable -Name TRIMMING -Value $true -Option Constant
} else {
	Set-Variable -Name TRIMMING -Value $false -Option Constant
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-type -AssemblyName microsoft.VisualBasic
Add-Type -AssemblyName UIAutomationClient

Set-Variable -Name FILEPATH -Value ([System.Environment]::GetFolderPath('Desktop')) -Option Constant
Set-Variable -Name IMAGEMAGICK -Value 'C:\Program Files\ImageMagick-7.1.1-Q16-HDRI\magick.exe' -Option Constant
Set-Variable -Name PNG_PREFIX -Value ($TARGETAPP + '-screen') -Option Constant

<#
	1. get rectangle of $TARGETAPP window
#>

function isIconic($in_e) {
    $supportedPatterns = $in_e.GetSupportedPatterns()
    $isSupported = $supportedPatterns.Id -contains [System.Windows.Automation.WindowPattern]::Pattern.Id
	if ($isSupported) {
		$pattern = $in_e.GetCurrentPattern([System.Windows.Automation.WindowPattern]::Pattern)
		return $pattern.Current.WindowVisualState -eq [System.Windows.Automation.WindowVisualState]::Minimized
	}
	return $false
}

function getProcess($in_app) {
	$processList = Get-Process -Name $in_app -ErrorAction SilentlyContinue
	if ($null -eq $processList) {
		Write-Host "error : can not find $($in_app)"
		return $null
	}
	foreach($process in $processList) {
		if ($process.MainWindowHandle -eq 0)  {
			continue
		}
		$autoElem = [System.Windows.Automation.AutomationElement]::FromHandle($process.MainWindowHandle)
		if (isIconic $autoElem) {
			continue
		}
		if ($autoElem.Current.Name) {
			[Microsoft.VisualBasic.Interaction]::AppActivate($process.ID)
			return $process
		}
	}
	Write-Host "error : $($in_app) is not normal state"
	return $null
}

function getDrawingRect($in_hWnd) {
	$autoElem = [System.Windows.Automation.AutomationElement]::FromHandle($in_hWnd)
	$r = $autoElem.Current.BoundingRectangle
	# Write-Host "X:$($r.X), Y:$($r.Y), W:$($r.Width), H:$($r.Height)"
	return New-Object System.Drawing.Rectangle(
		($r.X + $WIN_MARGIN_L),
		($r.Y + $WIN_MARGIN_T),
		($r.Width - $WIN_MARGIN_L - $WIN_MARGIN_R),
		($r.Height - $WIN_MARGIN_T - $WIN_MARGIN_B)
	)
}

$targetProcess = getProcess $TARGETAPP

if ($targetProcess) {
	$targetRect = getDrawingRect $targetProcess.MainWindowHandle
} else {
	exit
}

<#
	2. copy whole primary screen to $screenBmp
#>

$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$screenBmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
# Write-Host "W:$($bounds.Width), H:$($bounds.Height)"

$graphics = [System.Drawing.Graphics]::FromImage($screenBmp)
$graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
[System.Windows.Forms.Clipboard]::SetImage($screenBmp)

<#
	3. crop $screen of '2' using rect of '1'
#>

$screenRect = New-Object System.Drawing.Rectangle(0, 0, $bounds.Width, $bounds.Height)

if ($screenRect.Contains($targetRect)) {
	$targetBmp = $screenBmp.Clone($targetRect, $screenBmp.PixelFormat)
} else {
	Write-Host 'error : rect of screen does not contain rect of target'
	exit
}

<#
	4. save bitmap of '3' and exec $IMAGEMAGICK
#>

function getSavePath() {
	$index = 0
	do {
		$tmpPath = Join-Path -Path $FILEPATH -ChildPath "$($PNG_PREFIX)-$(('{0:D3}' -f $index)).png"
		$index++
	} while (Test-Path $tmpPath)
	return $tmpPath
}

$savePath = getSavePath
$targetBmp.Save($savePath, [System.Drawing.Imaging.ImageFormat]::Png)

if (Test-Path $IMAGEMAGICK) {
	$arguments = @($savePath)
	if ($TRIMMING) {
		$arguments += '-fuzz 10%'
		$arguments += '-trim +repage'
	}
	$arguments += '-colors 256'
	$arguments += '-depth 8'
	$arguments += $RESIZE
	$arguments += $savePath
	Start-Process $IMAGEMAGICK -ArgumentList $arguments -NoNewWindow -Wait
} else {
	Write-Host "note : there is not $($IMAGEMAGICK)"
}

$graphics.Dispose()
$screenBmp.Dispose()
$targetBmp.Dispose()
