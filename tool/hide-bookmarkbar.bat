@powershell "$THISFILE=\"%~f0\"; $PSCODE=[scriptblock]::create((Get-Content $THISFILE | Where-Object {$_.readcount -gt 1}) -join \"`n\"); & $PSCODE" & goto:eof

<#
	Using this script, you can hide the bookmarkbar if you forget the shortcut.
#>

add-type -AssemblyName microsoft.VisualBasic
add-type -AssemblyName System.Windows.Forms

$ps = Get-Process -Name 'chrome'
foreach($process in $ps) {
	if ($process.MainWindowHandle -ne 0)  {
		write-host $process.MainWindowTitle
		[Microsoft.VisualBasic.Interaction]::AppActivate($process.ID);
		[System.Windows.Forms.SendKeys]::SendWait("^+b");
	}
}
