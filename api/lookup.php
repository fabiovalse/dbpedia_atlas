<?php
	header('content-type: application/json; charset=utf-8');

	include "jena.php";

	if (isset($_GET['text'])) {
		$text = utf8_decode($_GET['text']);
		$text = str_replace(" ", "%20", $text);

		$command = 'curl -H "Accept: application/json" "http://localhost:8112?query=' . $text . '"';

		$result = json_decode(shell_exec($command));

		foreach ($result as $entity) {
			$query_result = run_query(urlencode("SELECT ?i ?j ?label {<" . format_uri($entity->ref) . "> <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i; <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j. OPTIONAL { <" . format_uri($entity->ref) . "> <http://www.w3.org/2000/01/rdf-schema#label> ?label.}}"));
			$data[] = array("uri" => format_uri($entity->ref), "label" => $query_result["results"]["bindings"][0]["label"]["value"], "i" => $query_result["results"]["bindings"][0]["i"]["value"], "j" => $query_result["results"]["bindings"][0]["j"]["value"], "in_jena" => count($query_result["results"]["bindings"]) == 1);
		}

		echo json_encode($data);
	}

	function format_uri($uri) {
		return "http://data.linkedmdb.org/resource/" . $uri;
	}
?>