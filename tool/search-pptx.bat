@powershell "$THISFILE=\"%~f0\"; $PSCODE=[scriptblock]::create((Get-Content $THISFILE | Where-Object {$_.readcount -gt 1}) -join \"`n\"); & $PSCODE %*" & goto:eof

$keyword = Read-Host "input keyword to serch pptx"

$searchDirectory = Split-Path -Parent -Path $THISFILE

$foundFiles = @()

Add-Type -AssemblyName System.IO.Compression.FileSystem

Get-ChildItem -Path $searchDirectory -Filter *.pptx -Recurse | ForEach-Object {
	$pptxFile = $_.FullName
	$zipFile = [System.IO.Compression.ZipFile]::OpenRead($pptxFile)
	$xmlObject = $zipFile.Entries | Where-Object { $_.FullName -like "ppt/slides/slide*.xml" } | ForEach-Object {
		$stream = $_.Open()
		$reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
		$ret = [xml]$reader.ReadToEnd()
		$reader.Close()
		$stream.Close()
		return $ret
	}
	$zipFile.Dispose()
	if ($xmlObject | Where-Object { $_.OuterXml -match $keyword }) {
		$foundFiles += $pptxFile
	}
}

if ($foundFiles.Count -gt 0) {
	Write-Output "target files :"
	$foundFiles
} else {
	Write-Output "not found"
}

pause
