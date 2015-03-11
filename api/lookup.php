<?php
	header('content-type: application/json; charset=utf-8');

	$hits = 10;
	$class = "";

	if (isset($_GET['text'])) {
		$text = utf8_decode($_GET['text']);
		$text = str_replace(" ", "%20", $text);

		if (isset($_GET['hits']))
			$hits = $_GET['hits'];

		if (isset($_GET['class']))
			$class = $_GET['class'];

		$command = 'curl -H "Accept: application/json" "http://lookup.dbpedia.org/api/search.asmx/KeywordSearch?QueryString=' . $text . '&QueryClass=' . $class . '&MaxHits=' . $hits . '"';
		$result = json_decode(shell_exec($command));

		foreach ($result->results as $enity) {
			$data[] = array("uri" => $enity->uri);
		}

		echo json_encode($data);
	}
?>