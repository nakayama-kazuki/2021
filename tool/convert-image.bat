@powershell "(Get-Clipboard -Format Image).Save([console]::OpenStandardOutput(), [System.Drawing.Imaging.ImageFormat]::Png);" | "C:\xampp\php\php" -r "$PHPCODE = implode('', array_slice(file('%0'), 1)); eval($PHPCODE);" & goto:eof

define('BRANCH', 'XX');
define('FORMAT', '%0' . strlen(BRANCH) . 's');
define('FNAME', 'copied-image-as-png-' . BRANCH . '.png');

function decide_palette($in_im)
{
	$w = imagesx($in_im);
	$h = imagesy($in_im);
	$counter = array();
	for ($y = 0; $y < $h; $y++) {
		for ($x = 0; $x < $w; $x++) {
			$color = imagecolorat($in_im, $x, $y);
			if (array_key_exists($color, $counter)) {
				$counter[$color]++;
			} else {
				$counter[$color] = 1;
			}
		}
	}
	define('THRESHOLD', 10000);
	$major_colors = 0;
	if ($w * $h > THRESHOLD) {
		$minimum = $w * $h / THRESHOLD;
	} else {
		$minimum = 0;
	}
	foreach ($counter as $cnt) {
		if ($cnt > $minimum) {
			$major_colors++;
		}
	}
	for ($i = 1; $i <= 8; $i++) {
		$palette = 2 ** $i;
		if ($palette >= $major_colors) {
			break;
		}
	}
	echo "palette : {$palette}\n";
	return $palette;
}

function png_file($in_path)
{
	$i = 0;
	do {
		$filename = "{$in_path}/" . str_replace(BRANCH, sprintf(FORMAT, $i++), FNAME);
	} while (file_exists($filename));
	return $filename;
}

$im = @imagecreatefrompng('php://stdin');

if ($im === FALSE) {
	echo "error (no image)\n";
	exit;
} else {
	if (!imageistruecolor($im)) {
		imagepalettetotruecolor($im);
	}
}

$w = imagesx($im);
$h = imagesy($im);

define('WCAP', 1000);

if ($w > WCAP) {
	echo "resizing ...\n";
	$im_resize = imagecreatetruecolor(WCAP, $h * WCAP / $w);
	imagecopyresampled($im_resize, $im, 0, 0, 0, 0, WCAP, $h * WCAP / $w, $w, $h);
	imagetruecolortopalette($im_resize, FALSE, decide_palette($im_resize));
	imagepng($im_resize, png_file(__DIR__));
} else {
	imagetruecolortopalette($im, FALSE, decide_palette($im));
	imagepng($im, png_file(__DIR__));
}

