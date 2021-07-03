@powershell "$PATH=\"%~f0\"; $EXEC=[scriptblock]::create((Get-Content $PATH | Where-Object {$_.readcount -gt 1}) -join\"`n\"); & $EXEC" & goto:eof

$src = Get-Clipboard -Format Text;

$urls = @();
foreach ($line in $src) {
	if ($line.IndexOf('https:') -eq 0)  {
		$urls += $line;
		Write-Host "open $line";
	}
}

$url = $urls -join " ";
$option = "--incognito --new-window $url";
$chrome = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe";

Start-Process -FilePath $chrome -ArgumentList $option;
