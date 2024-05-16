@powershell "$THISFILE=\"%~f0\"; $PSCODE=[scriptblock]::create((Get-Content $THISFILE | Where-Object {$_.readcount -gt 1}) -join \"`n\"); & $PSCODE %*" & goto:eof

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO

function Convert-ImageStream {
	param([System.IO.Stream]$inputStream, [int]$quality)
	
	$outputStream = New-Object System.IO.MemoryStream
	$startInfo = New-Object System.Diagnostics.ProcessStartInfo
	$startInfo.FileName = "magick"
	$startInfo.Arguments = "convert - -quality $quality png:-"
	$startInfo.RedirectStandardInput = $true
	$startInfo.RedirectStandardOutput = $true
	$startInfo.UseShellExecute = $false
	$startInfo.CreateNoWindow = $true

	$process = New-Object System.Diagnostics.Process
	$process.StartInfo = $startInfo
	$process.Start()

	$inputStream.CopyTo($process.StandardInput.BaseStream)
	$process.StandardInput.Close()
	$process.StandardOutput.BaseStream.CopyTo($outputStream)
	$process.WaitForExit()

	$outputStream.Position = 0
	return $outputStream
}

if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
	$img = [System.Windows.Forms.Clipboard]::GetImage()
	$stream = New-Object System.IO.MemoryStream
	$img.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
	$stream.Position = 0

	$compressedStream = Convert-ImageStream -inputStream $stream -quality 85
	$newImg = [System.Drawing.Image]::FromStream($compressedStream)
	[System.Windows.Forms.Clipboard]::SetImage($newImg)

	Write-Output "Image compressed and set back to clipboard."
} else {
	Write-Output "No image in clipboard."
}
