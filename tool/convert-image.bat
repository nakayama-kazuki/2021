@powershell "(Get-Clipboard -Format Image).Save([console]::OpenStandardOutput(), [System.Drawing.Imaging.ImageFormat]::Png);" | "C:\xampp\php\php" -r "$PHPCODE = implode('', array_slice(file('%0'), 1)); eval($PHPCODE);" & goto:eof

$im = imagecreatefrompng('php://stdin');
imagepalettetotruecolor($im);
imagetruecolortopalette($im, FALSE, 255);
imagepng($im, __DIR__ . '\copied-image-as-png8.png');

