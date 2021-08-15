<?php

define('FONTSIZE', 5);
define('FONTW', imagefontwidth(FONTSIZE));
define('FONTH', imagefontheight(FONTSIZE));
define('IMG_MARGIN', 10);
define('TEXT_MAXLEN', 100);
define('MATCH', (array_key_exists('m', $_GET) ? $_GET['m'] : null));

$headers = apache_request_headers();
$hedaer_lines = array();
foreach ($headers as $key => $val) {
	if (MATCH) {
		if (strpos(strtoupper($key), strtoupper(MATCH)) === FALSE) {
			continue;
		}
	}
	$hedaer_line = "{$key}: {$val}";
	if (strlen($hedaer_line) > TEXT_MAXLEN) {
		$hedaer_line = substr($hedaer_line, 0, TEXT_MAXLEN) . ' ...';
	}
	array_push($hedaer_lines, $hedaer_line);
}

header('Content-Type: image/gif');

$maxw = 0;
$maxh = 0;
foreach ($hedaer_lines as $line) {
	$w = FONTW * strlen($line);
	if ($w > $maxw) {
		$maxw = $w;
	}
	$maxh += FONTH;
}
$maxw += IMG_MARGIN * 2;
$maxh += IMG_MARGIN * 2;

$im = imagecreate($maxw, $maxh);
$bg = imagecolorallocate($im, 200, 200, 200);
$fg = imagecolorallocate($im, 0, 0, 0);

for ($y = 0; $y < count($hedaer_lines); $y++) {
	for ($x = 0; $x < strlen($hedaer_lines[$y]); $x++) {
		$xpos = $x * FONTW + IMG_MARGIN;
		$ypos = $y * FONTH + IMG_MARGIN;
		imagechar($im, FONTSIZE, $xpos, $ypos, substr($hedaer_lines[$y], $x, 1), $fg);
	}
}

imagegif($im);
imagedestroy($im);

?>
