@powershell "$THISFILE=\"%~f0\"; $PSCODE=[scriptblock]::create((Get-Content $THISFILE | Where-Object {$_.readcount -gt 1}) -join \"`n\"); & $PSCODE" & goto:eof

<#
	Using this script, you can open URLs copied to the clipboard.
#>

$copiedText = Get-Clipboard -Format Text;

$urls = @();
foreach ($line in $copiedText) {
	if ($line.IndexOf("https:") -eq 0)  {
		$urls += $line;
		Write-Host "open $line";
	}
}

if ($urls.Length -gt 0) {
	$url = $urls -join " ";
	$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe";
	Start-Process -FilePath $chrome -ArgumentList "--incognito --new-window $url";
} else {
	[System.Windows.Forms.MessageBox]::Show("404 URL Not Found");
}
