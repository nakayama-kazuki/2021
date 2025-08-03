@powershell "(Get-Clipboard -Format Image).Save([console]::OpenStandardOutput(), [System.Drawing.Imaging.ImageFormat]::Png);" | "C:\xampp\php\php" -r "$PHPCODE = implode('', array_slice(file('%0'), 1)); eval($PHPCODE);" %1 & goto:eof

define('MAX_BIT', 8);
define('AUTO_DETECT_PALETTE', TRUE);

function detect_palette($in_im)
{
	if (!AUTO_DETECT_PALETTE) {
		return (2 ** MAX_BIT);
	}
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
	for ($i = 1; $i <= MAX_BIT; $i++) {
		$palette = 2 ** $i;
		if ($palette >= $major_colors) {
			break;
		}
	}
	echo "palette : {$palette}\n";
	return $palette;
}

define('BRANCH', 'XX');
define('FORMAT', '%0' . strlen(BRANCH) . 's');
//define('FNAME', 'copied-image-as-png-' . BRANCH . '.png');
define('FNAME', 'png-' . substr(md5(date('Y-m-d')), 0, 4) . '-' . BRANCH . '.png');

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

if (count($argv) > 1) {
	$wcap = $argv[1];
} else {
	$wcap = 1000;
}

$srcw = imagesx($im);
$srch = imagesy($im);
$dstw = ($srcw > $wcap) ? $wcap : $srcw;
$dsth = ($srcw > $wcap) ? $srch * $wcap / $srcw : $srch;

$im_dst = imagecreatetruecolor($dstw, $dsth);
imagecopyresampled($im_dst, $im, 0, 0, 0, 0, $dstw, $dsth, $srcw, $srch);
imagetruecolortopalette($im_dst, FALSE, detect_palette($im_dst));
imagepng($im_dst, png_file(__DIR__));

imagedestroy($im_dst);
imagedestroy($im);
