@powershell "(Get-Clipboard -Format Image).Save([console]::OpenStandardOutput(), [System.Drawing.Imaging.ImageFormat]::Jpeg);" | "C:\xampp\php\php" -r "$PHPCODE = implode('', array_slice(file('%0'), 1)); eval($PHPCODE);" | clip & goto:eof

echo "<img src='data:image/jpeg;base64," . base64_encode(file_get_contents('php://stdin')) . "' />";
