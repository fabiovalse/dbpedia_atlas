<?php
	header('content-type: application/json; charset=utf-8');

	include "jena.php";
	$limit = 20;

	if (isset($_GET["string"])) {
		$query = urlencode('SELECT DISTINCT ?x {?x ?y ?z .FILTER(STRSTARTS(STR(?x), "http://dbpedia.org/resource/") && REGEX(STR(?x), "' . $_GET["string"] . '"))} LIMIT' . $limit);
		$result = make_query($query);

		echo json_encode($result);
	}
?>