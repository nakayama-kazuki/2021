@powershell "$THISFILE=\"%~f0\"; $PSCODE=[scriptblock]::create((Get-Content $THISFILE | Where-Object {$_.readcount -gt 1}) -join \"`n\"); & $PSCODE %*" & goto:eof

param(
    [string]$basePath
)

if (-not $basePath) {
	Write-Host 'input path' -ForegroundColor Red
	exit 1
}

if (-not (Test-Path -Path $basePath)) {
	Write-Host 'not found' -ForegroundColor Red
	exit 1
}

$yyyymmdd = Get-Date;
$yyyy = $yyyymmdd.ToString('yyyy');
$yyyymm = $yyyymmdd.ToString('yyyyMM');
$yyyymmdd = $yyyymmdd.ToString('yyyyMMdd');

$y_path = Join-Path -Path $basePath -ChildPath $yyyy;
if (-Not (Test-Path -Path $y_path)) {
	New-Item -Path $y_path -ItemType Directory;
}

$m_path = Join-Path -Path $y_path -ChildPath $yyyymm;
if (-Not (Test-Path -Path $m_path)) {
    New-Item -Path $m_path -ItemType Directory;
}

$d_path = Join-Path -Path $m_path -ChildPath $yyyymmdd;
if (-Not (Test-Path -Path $d_path)) {
    New-Item -Path $d_path -ItemType Directory;
}

Start-Process -FilePath "explorer.exe" -ArgumentList $d_path;
