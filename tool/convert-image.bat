@powershell "(Get-Clipboard -Format Image).Save([console]::OpenStandardOutput(), [System.Drawing.Imaging.ImageFormat]::Png);" | "C:\xampp\php\php" -r "$PHPCODE = implode('', array_slice(file('%0'), 1)); eval($PHPCODE);" & goto:eof

$im = imagecreatefrompng('php://stdin');
imagepalettetotruecolor($im);

$w = imagesx($im);
$h = imagesy($im);

define('WCAP', 800);

if ($w > WCAP) {
	$im_resize = imagecreatetruecolor(WCAP, $h * WCAP / $w);
	imagecopyresampled($im_resize, $im, 0, 0, 0, 0, WCAP, $h * WCAP / $w, $w, $h);
	imagetruecolortopalette($im_resize, FALSE, 255);
	imagepng($im_resize, __DIR__ . '\copied-image-as-png8.png');
} else {
	imagetruecolortopalette($im, FALSE, 255);
	imagepng($im, __DIR__ . '\copied-image-as-png8.png');
}

