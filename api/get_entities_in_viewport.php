<?php
	header('content-type: application/json; charset=utf-8');

	include "jena.php";
	$limit = 100;

	$data = array();

	if (isset($_GET["top_j"]) && isset($_GET["bottom_j"]) && isset($_GET["left_i"]) && isset($_GET["right_i"])) {
		$query = urlencode("PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>SELECT ?x ?i ?j {?x <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i;<http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j .FILTER (xsd:integer(?i) > " . $_GET["left_i"] . " && xsd:integer(?i) < " . $_GET["right_i"] . " && xsd:integer(?j) > " . $_GET["bottom_j"] . " && xsd:integer(?j) < " . $_GET["top_j"] . ")} LIMIT " . $limit);
		$result = make_query($query);

		foreach ($result["results"]["bindings"] as $entity) {
			$data[] = array("uri" => $entity["x"]["value"], "data_properties" => array("<http://wafi.iit.cnr.it/lod/ns/atlas#i>" => array($entity["i"]), "<http://wafi.iit.cnr.it/lod/ns/atlas#j>" => array($entity["j"])));
		}

		echo json_encode($data);
	}
?>