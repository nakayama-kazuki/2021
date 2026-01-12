@powershell "$THISFILE=\"%~f0\"; $PSCODE=[scriptblock]::create((Get-Content $THISFILE | Where-Object {$_.readcount -gt 1}) -join \"`n\"); & $PSCODE" & goto:eof

<#
	Using this script, you can register text copied to the clipboard into a dictionary.
	Change 'C:\_PATH_\_TO_\IMEJP\IMJPDCT.EXE' to match your environment.
#>

Start-Process 'C:\_PATH_\_TO_\IMEJP\IMJPDCT.EXE';
Start-Sleep -Seconds 1;
Add-Type -AssemblyName System.Windows.Forms;
$text = [System.Windows.Forms.Clipboard]::GetText();
if ($text.Length -ge 0 -and $text.Length -le 20) {
	[System.Windows.Forms.SendKeys]::SendWait("^{v}");
}
