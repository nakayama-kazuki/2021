@powershell "Get-Clipboard -Format Text" | "C:\xampp\php\php" -r "$PHPCODE = implode('', array_slice(file('%0'), 1)); eval($PHPCODE);" | clip & goto:eof

$buffer = explode('>', file('php://stdin')[0]);
$output = array();

for ($i = 0; $i < count($buffer); $i++) {
	if (trim($buffer[$i])) {
		$pos = strpos($buffer[$i], '<');
		array_push($output, substr($buffer[$i], $pos + 1));
	}
}

echo implode('; ', $output);
