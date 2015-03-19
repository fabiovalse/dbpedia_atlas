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

		$command = 'curl -H "Accept: application/json" "http://localhost:8111/api/search/KeywordSearch?QueryString=' . $text . '&QueryClass=' . $class . '&MaxHits=' . $hits . '"';
		//$command = 'curl -H "Accept: application/json" "http://wafi.iit.cnr.it/fabio8111/api/search/KeywordSearch?QueryString=' . $text . '&QueryClass=' . $class . '&MaxHits=' . $hits . '"';
		$result = json_decode(shell_exec($command));

		foreach ($result->results as $entity) {
			$query_result = run_query(urlencode("SELECT ?i ?j ?msc {<" . format_uri($entity->uri) . "> <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i; <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j. OPTIONAL { <" . format_uri($entity->uri) . "> <http://wafi.iit.cnr.it/lod/ns/atlas#msc> ?msc.}}"));
			$data[] = array("uri" => format_uri($entity->uri), "i" => $query_result["results"]["bindings"][0]["i"]["value"], "j" => $query_result["results"]["bindings"][0]["j"]["value"], "msc" => $query_result["results"]["bindings"][0]["msc"]["value"], "in_jena" => count($query_result["results"]["bindings"]) == 1);
		}

		echo json_encode($data);
	}

	function format_uri($uri) {
		$target = array("%28", "%29", "%2C", "%27", "%21");
		$replacement = array("(", ")", ",", "'", "!");

		$uri = "http://dbpedia.org/resource/" . urlencode(end(split("/", $uri)));
		$uri = str_replace($target, $replacement, $uri);

		return $uri;
	}
?>