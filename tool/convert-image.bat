@powershell "(Get-Clipboard -Format Image).Save([console]::OpenStandardOutput(), [System.Drawing.Imaging.ImageFormat]::Png);" | "C:\xampp\php\php" -r "$PHPCODE = implode('', array_slice(file('%0'), 1)); eval($PHPCODE);" & goto:eof

define('DIGIT', 'XX');
define('FORMAT', '%0' . strlen(DIGIT) . 's');
define('FNAME', 'copied-image-as-png8-' . DIGIT . '.png');

function png8file($in_path)
{
	$i = 0;
	do {
		$filename = "{$in_path}/" . str_replace(DIGIT, sprintf(FORMAT, $i++), FNAME);
	} while (file_exists($filename));
	return $filename;
}

$im = imagecreatefrompng('php://stdin');
imagepalettetotruecolor($im);

$w = imagesx($im);
$h = imagesy($im);

define('WCAP', 800);

if ($w > WCAP) {
	$im_resize = imagecreatetruecolor(WCAP, $h * WCAP / $w);
	imagecopyresampled($im_resize, $im, 0, 0, 0, 0, WCAP, $h * WCAP / $w, $w, $h);
	imagetruecolortopalette($im_resize, FALSE, 255);
	imagepng($im_resize, png8file(__DIR__));
} else {
	imagetruecolortopalette($im, FALSE, 255);
	imagepng($im, png8file(__DIR__));
}

