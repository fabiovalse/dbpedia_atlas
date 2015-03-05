<?php
	header('content-type: application/json; charset=utf-8');

	include "jena.php";
	$limit = 20;

	if (isset($_GET["string"])) {
		$query = urlencode('SELECT DISTINCT ?x {?x ?y ?z .FILTER(STRSTARTS(STR(?x), "http://dbpedia.org/resource/") && REGEX(STR(?x), "' . $_GET["string"] . '", "i"))} LIMIT' . $limit);
		$result = make_query($query);

		foreach ($result["results"]["bindings"] as $entity) {
			$data[] = array("uri" => $entity["x"]["value"]);
		}

		echo json_encode($data);
	}
?>