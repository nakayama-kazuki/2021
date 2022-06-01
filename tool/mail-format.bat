@powershell "Get-Clipboard -Format Text" | "C:\xampp\php\php" -r "$PHPCODE = implode('', array_slice(file('%0'), 1)); eval($PHPCODE);" | clip & goto:eof

function remove_safelinks($in_line)
{
	$safelinks = '/https\:\/\/.+\?url\=(https?\%3A\%2F\%2F[^\&]+).+\&reserved\=0/';
	if (preg_match($safelinks, $in_line, $matches) === 0) {
		return $in_line;
	} else {
		return str_replace($matches[0], rawurldecode($matches[1]), $in_line);
	}
}

define('SPACE', ' ');
define('TAB2SP', 4);

function make_space($in_repeat)
{
	$space = '';
	for ($i = 0; $i < $in_repeat; $i++) {
		$space .= SPACE;
	}
	return $space;
}

function count_left_space($in_line)
{
	for ($i = 0; $i < strlen($in_line); $i++) {
		if (substr($in_line, $i, 1) !== SPACE) {
			return $i;
		}
	}
}

$lines = file('php://stdin');

$maxSpace = 0;
$startIndex = 0;
for ($i = 0; $i < count($lines); $i++) {
	$lines[$i] = remove_safelinks($lines[$i]);
	$lines[$i] = str_replace("\t", make_space(TAB2SP), $lines[$i]);
	if (!trim($lines[$i])) {
		continue;
	}
	$currentSpace = count_left_space($lines[$i]);
	if ($currentSpace === $maxSpace) {
		continue;
	} else {
		if ($currentSpace < $maxSpace) {
			$startIndex = $i;
		}
		$maxSpace = $currentSpace;
	}
}

for ($i = 0; $i < count($lines); $i++) {
	if ($i < $startIndex) {
		echo $lines[$i];
	} else {
		echo trim($lines[$i]) . "\n";
	}
}

