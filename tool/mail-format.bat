@powershell "Get-Clipboard -Format Text" | "C:\xampp\php\php" -r "$PHPCODE = implode('', array_slice(file('%0'), 1)); eval($PHPCODE);" | clip & goto:eof

define('GT', chr(62));
define('TAB', chr(9));
define('CRLF', chr(10));
define('SPACE', chr(32));
define('TAB2SP', 4);

function remove_safelinks($in_str)
{
	$safelinks = '/https\:\/\/.+\?url\=(https?\%3A\%2F\%2F[^\&]+).+reserved\=0/';
	if (preg_match($safelinks, $in_str, $matches) === 0) {
		return $in_str;
	} else {
		return str_replace($matches[0], rawurldecode($matches[1]), $in_str);
	}
}

function remove_lt_email_gt($in_str)
{
	return preg_replace('/<[^@]+@[^>]+>/', '', $in_str);
}

function remove_space_in_gt($in_str)
{
	$parts = explode(GT, $in_str);
	if (count($parts) < 3) {
		return $in_str;
	}
	for ($i = 1; $i < count($parts) - 1; $i++) {
		if (!$parts[$i]) {
			continue;
		}
		if (ctype_space($parts[$i])) {
			$parts[$i] = '';
		} else {
			break;
		}
	}
	return implode(GT, $parts);
}

function make_space($in_repeat)
{
	$space = '';
	for ($i = 0; $i < $in_repeat; $i++) {
		$space .= SPACE;
	}
	return $space;
}

function replace_tab_to_space($in_str)
{
	return str_replace(TAB, make_space(TAB2SP), $in_str);
}

function replace_blankline($in_str)
{
	return preg_replace('/\A\s*\z/', CRLF, $in_str);
}

function count_left_space($in_line)
{
	for ($i = 0; $i < strlen($in_line); $i++) {
		if (substr($in_line, $i, 1) !== SPACE) {
			return $i;
		}
	}
	return $i;
}

function echo_formatted_mail($in_lines)
{
	$filters = array(
		'remove_safelinks',
		'remove_lt_email_gt',
		'remove_space_in_gt',
		'replace_tab_to_space',
		'replace_blankline'
	);
	for ($i = 0; $i < count($in_lines); $i++) {
		foreach ($filters as $filter) {
			$in_lines[$i] = call_user_func($filter, $in_lines[$i]);
		}
	}
	$indent = array();
	$minSpace = PHP_INT_MAX;
	for ($i = count($in_lines) - 1; $i >= 0; $i--) {
		if (!ctype_space($in_lines[$i])) {
			$currentSpace = count_left_space($in_lines[$i]);
			if ($minSpace > $currentSpace) {
				$minSpace = $currentSpace;
			}
		}
		array_push($indent, $minSpace);
	}
	$indent = array_reverse($indent);
	for ($i = 0; $i < count($in_lines); $i++) {
		if ($indent[$i] < PHP_INT_MAX) {
			echo GT;
			if (!ctype_space($in_lines[$i])) {
				echo SPACE . substr($in_lines[$i], $indent[$i]);
			} else {
				echo CRLF;
			}
		}
	}
}

$test_data = <<<EOTEST

aaaa
  aaaa
aaaa
aaaa
               
  aaaa
  aaaa
  >>	>> >> >  > aaaa
  >>	>> >> >  > aaaa
    

	aaaa
		aaaa <hoge@yahoo.co.jp>; aaaa
		aaaa <fuga@yahoo.co.jp>     >> >> >  > aaaa
	aaaa
    

    

EOTEST;

if (TRUE) {
	$lines = file('php://stdin');
} else {
	header('Content-Type: text/plain;');
	$lines = explode(CRLF, $test_data);
}

echo_formatted_mail($lines);
