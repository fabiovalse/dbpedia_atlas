<?php
	header('content-type: application/json; charset=utf-8');

	include "jena.php";
	
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

		foreach ($result->results as $entity) {
			$in_jena = make_query(urlencode("ASK {<" . $entity->uri . "> <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i . <" . $entity->uri . "> <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j}"));

			$data[] = array("uri" => $entity->uri, "in_jena" => $in_jena["boolean"]);
		}

		echo json_encode($data);
	}
?>