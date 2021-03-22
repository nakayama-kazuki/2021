<?php

function magic($in_no, $in_digit = 5)
{
	return substr(md5($in_no), 0, $in_digit);
}

$C_SCRIPT = $_SERVER['SCRIPT_NAME'];
$C_WORKER = magic(0);

switch ($_SERVER['QUERY_STRING']) {

/*
	------
	Worker
	------
*/

case $C_WORKER :
	header('Content-Type: text/javascript');
	print <<<EOWORKER
function wait(in_msec)
{
	let cnt = 0;
	let start = Date.now();
	while (Date.now() - start < in_msec) {
		cnt++;
	}
	return cnt;
}
postMessage(wait(1000));
EOWORKER;
	break;

/*
	----
	Test
	----
*/

default :
	print <<<EOTEST
<div id='disp'></div>
<script>

'use strict';

function disp(in_dat)
{
	let div = document.createElement('DIV');
	div.innerText = in_dat;
	document.getElementById('disp').appendChild(div);
}

const delay = [100, 200, 300];

let start = Date.now();

for (let i = 0; i < delay.length; i++) {
	window.setTimeout(() => {
		disp('event[' + i + '] (set at ' + delay[i] + 'ms) start : ' + ((Date.now()) - start));
		let worker = new Worker('{$C_SCRIPT}?{$C_WORKER}');
		worker.onmessage = function(e) {
			disp(e.data);
		}
	}, delay[i]);
}

</script>
EOTEST;
	break;
}

?>
