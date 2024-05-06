@powershell "$THISFILE=\"%~f0\"; $PSCODE=[scriptblock]::create((Get-Content $THISFILE | Where-Object {$_.readcount -gt 1}) -join \"`n\"); & $PSCODE %*" & goto:eof

Set-Variable -Name SEPARATOR_COMMAND -Value 'PSCODE' -Option Constant
Set-Variable -Name SEPARATOR_OPTION -Value '\s+-' -Option Constant
Set-Variable -Name SEPARATOR_VALUE -Value '\s+' -Option Constant

function parseCommandParams() {
	$commandLine = ([Environment]::GetCommandLineArgs()) -split $SEPARATOR_COMMAND
	$options = $commandLine[$commandLine.Length - 1] -split $SEPARATOR_OPTION
	$res = @{}
	foreach ($option in $options) {
		if (!$option) {
			continue
		}
		$kv = $option -split $SEPARATOR_VALUE
		switch ($kv.Length) {
			1 {
				$res[$kv[0]] = $true
				break
			}
			2 {
				$res[$kv[0]] = $kv[1]
				break
			}
			default {
				$value = @()
				for ($i = 1; $i -lt $kv.Length; $i++) {
					$value += $kv[$i]
				}
				$res[$kv[0]] = $value
			}
		}
	}
	return $res
}

$INPUT_ARGS = parseCommandParams

Set-Variable -Name DEFAULT_MARGIN -Value 8 -Option Constant

$OPTION = @{
	't' = 'chrome'
	'op' = @('resize', '100%')
	'ml' = $DEFAULT_MARGIN
	'mt' = 0
	'mr' = $DEFAULT_MARGIN
	'mb' = $DEFAULT_MARGIN
	'trim' = $false
}

# foreach ($key in $OPTION.Keys) { : Collection was modified; enumeration operation may not execute.
foreach ($key in ($OPTION.Keys | ForEach-Object { $_ })) {
	if (!$INPUT_ARGS.ContainsKey($key)) {
		continue
	}
	$OPTION[$key] = $INPUT_ARGS[$key]
	# Write-Host "update $($key) : $($OPTION[$key])"
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-type -AssemblyName microsoft.VisualBasic
Add-Type -AssemblyName UIAutomationClient

Set-Variable -Name FILEPATH -Value ([System.Environment]::GetFolderPath('Desktop')) -Option Constant
Set-Variable -Name IMAGEMAGICK -Value 'C:\Program Files\ImageMagick-7.1.1-Q16-HDRI\magick-x.exe' -Option Constant
Set-Variable -Name PNG_PREFIX -Value ($OPTION['t'] + '-screen') -Option Constant

<#
	1. get rectangle of $OPTION['t'] window
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
		($r.X + $OPTION['ml']),
		($r.Y + $OPTION['mt']),
		($r.Width - $OPTION['ml'] - $OPTION['mr']),
		($r.Height - $OPTION['mt'] - $OPTION['mb'])
	)
}

$targetProcess = getProcess $OPTION['t']

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
	4. save bitmap of '3'
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

<#
	5. exec $IMAGEMAGICK
#>

if (Test-Path $IMAGEMAGICK) {
	$arguments = @($savePath)
	if ($OPTION['trim']) {
		$arguments += '-fuzz 10%'
		$arguments += '-trim +repage'
		Write-Host "error : $($in_app) is not normal state"

	}
	$arguments += '-colors 256'
	$arguments += '-depth 8'
	$arguments += "-$($OPTION['op'][0]) $($OPTION['op'][1])"
	$arguments += $savePath
	Start-Process $IMAGEMAGICK -ArgumentList $arguments -NoNewWindow -Wait
} else {
	$required = @('op', 'trim')
	foreach ($key in $required) {
		if ($INPUT_ARGS.ContainsKey($key)) {
			Write-Host "error : option '$($key)' needs $($IMAGEMAGICK)"
			break
		}
	}
}

<#
	6. finalize
#>

$graphics.Dispose()
$screenBmp.Dispose()
$targetBmp.Dispose()
