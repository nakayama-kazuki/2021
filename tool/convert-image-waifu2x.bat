@powershell "(Get-Clipboard -Format Image).Save([console]::OpenStandardOutput(), [System.Drawing.Imaging.ImageFormat]::Png);" | "C:\xampp\php\php" -r "$PHPCODE = implode('', array_slice(file('%0'), 1)); eval($PHPCODE);" & goto:eof

define('BRANCH', 'XX');
define('FORMAT', '%0' . strlen(BRANCH) . 's');
define('FNAME', 'copied-image-as-png-' . BRANCH . '.png');

function png_file($in_path)
{
	$i = 0;
	do {
		$filename = "{$in_path}/" . str_replace(BRANCH, sprintf(FORMAT, $i++), FNAME);
	} while (file_exists($filename));
	return $filename;
}

function png_tmp_file($in_create = FALSE)
{
	$filename = sys_get_temp_dir() . '/' . md5(rand()) . '.png';
	if ($in_create) {
		touch($filename);
	}
	register_shutdown_function(function($in_filename) {
		if (file_exists($in_filename)) {
			unlink($in_filename);
		}
	}, $filename);
	return $filename;
}

echo "step1 : copy from clipbord ...\n";
$im1 = @imagecreatefrompng('php://stdin');
if (!$im1) {
	echo "no image in clipbord ...\n";
	exit;
}
$file1 = png_tmp_file();
imagepng($im1, $file1);

echo "step2 : now converting by waifu2x-caffe ...\n";
$file2 = png_tmp_file();
$command = 'C:\kanakaya\git\waifu2x-caffe\waifu2x-caffe-cui.exe' . " -i {$file1} -o {$file2} -m noise -n 1 -p cpu";
exec($command, $message, $rcode);
imagedestroy($im1);

echo "step3 : write png file ...\n";
$im2 = @imagecreatefrompng($file2);
imagetruecolortopalette($im2, FALSE, 256);
imagepng($im2, png_file(__DIR__));
imagedestroy($im2);
