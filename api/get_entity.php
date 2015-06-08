<?php
	header('content-type: application/json; charset=utf-8');
	set_time_limit(0);

	include "jena.php";

	/*	Given the URI of entity, returns the triples in which it is subject and the triples in which it is object
	*/
	if (isset($_GET["uri"])) {
		$query = urlencode("SELECT ?s ?p ?o ?c ?label ?i ?j {{?g ?p ?o .OPTIONAL {?o <http://www.w3.org/2000/01/rdf-schema#label> ?label.}OPTIONAL {?o <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?o <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.}OPTIONAL {?o a ?c.FILTER (!STRSTARTS(STR(?c), 'http://xmlns.com/foaf/'))}FILTER (?g = <" . $_GET["uri"] . "> && ?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?s)}UNION{?s ?p ?g .OPTIONAL {?s <http://www.w3.org/2000/01/rdf-schema#label> ?label.}OPTIONAL {?s <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?s <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.}OPTIONAL {?s a ?c.FILTER (!STRSTARTS(STR(?c), 'http://xmlns.com/foaf/'))}FILTER (?g = <" . $_GET["uri"] . "> && ?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?o)}}");

		$result = run_query($query);

		/*echo json_encode($result);
		exit;*/

		$uri = $_GET["uri"];
	}
	/*	Given the coordinates (i, j) of a certain entity in the map, returns the triples of the entity (both in subject and object position)
	*/
	elseif (isset($_GET["i"]) && isset($_GET["j"])) {
		$i = $_GET["i"];
		$j = $_GET["j"];

		$query = urlencode('SELECT ?s ?p ?o ?c ?label ?i ?j {{?g <http://wafi.iit.cnr.it/lod/ns/atlas#i> "' . $i . '"^^<http://www.w3.org/2001/XMLSchema#integer>;<http://wafi.iit.cnr.it/lod/ns/atlas#j> "' . $j . '"^^<http://www.w3.org/2001/XMLSchema#integer>;?p ?o .OPTIONAL {?o <http://www.w3.org/2000/01/rdf-schema#label> ?label.}OPTIONAL {?o <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?o <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.}OPTIONAL {?o a ?c.FILTER (!STRSTARTS(STR(?c), "http://xmlns.com/foaf/"))}FILTER (?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?s)}UNION{?g <http://wafi.iit.cnr.it/lod/ns/atlas#i> "' . $i . '"^^<http://www.w3.org/2001/XMLSchema#integer>;<http://wafi.iit.cnr.it/lod/ns/atlas#j> "' . $j . '"^^<http://www.w3.org/2001/XMLSchema#integer>.?s ?p ?g .OPTIONAL {?s <http://www.w3.org/2000/01/rdf-schema#label> ?label.}OPTIONAL {?s <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?s <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.}OPTIONAL {?s a ?c.FILTER (!STRSTARTS(STR(?c), "http://xmlns.com/foaf/"))}FILTER (?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?o)}}');

		$result = run_query($query);

		$uri = $result["results"]["bindings"][0]["s"]["value"];
	}

	$data = array("ts" => $_GET["ts"], "uri" => $uri, "data_properties" => array(), "object_properties" => array("incoming" => array(), "outgoing" => array(), "itself" => array()), "types" => array());
	$current_entity = "";

	foreach ($result["results"]["bindings"] as $triple) {
		if ($triple["p"]["value"] == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" && strpos($triple["o"]["value"], "http://xmlns.com/foaf") > -1)
			continue;
		elseif ($triple["p"]["value"] == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
			array_push($data["types"], $triple["o"]);
		elseif ($triple["s"]["value"] == $uri && $triple["o"]["value"] == $uri)
			array_push($data["object_properties"]["itself"], $triple["p"]);
		# object_properties -> outgoing
		else if ($triple["s"]["value"] == $uri && strpos($triple["o"]["value"], "http://data.linkedmdb.org/resource/") > -1) {
			if ($current_entity != $triple["o"]["value"]) {
				$current_entity = $triple["o"]["value"];

				if (array_key_exists("i", $triple)) {
					if ($triple["c"] != null)
						array_push($data["object_properties"]["outgoing"], array("p" => $triple["p"], "o" => $triple["o"], "c" => array($triple["c"]), "label" => (array_key_exists('label', $triple) ? $triple["label"] : array("value" => "")), "i" => $triple["i"], "j" => $triple["j"]));
					else
						array_push($data["object_properties"]["outgoing"], array("p" => $triple["p"], "o" => $triple["o"], "c" => array(), "label" => (array_key_exists('label', $triple) ? $triple["label"] : array("value" => "")), "i" => $triple["i"], "j" => $triple["j"]));
				}
				else
					array_push($data["object_properties"]["outgoing"], array("p" => $triple["p"], "o" => $triple["o"]));
			} else {
				array_push($data["object_properties"]["outgoing"][count($data["object_properties"]["outgoing"])-1]["c"], $triple["c"]);
			}
		}
		# object_properties -> incoming
		elseif ($triple["o"]["value"] == $uri && strpos($triple["s"]["value"], "http://data.linkedmdb.org/resource/") > -1) {

			if ($current_entity != $triple["s"]["value"]) {
				$current_entity = $triple["s"]["value"];
				
				if (array_key_exists("i", $triple)) {
					if ($triple["c"] != null)
						array_push($data["object_properties"]["incoming"], array("s" => $triple["s"], "p" => $triple["p"], "c" => array($triple["c"]), "label" => (array_key_exists('label', $triple) ? $triple["label"] : array("value" => "")), "i" => $triple["i"], "j" => $triple["j"]));
					else
						array_push($data["object_properties"]["incoming"], array("s" => $triple["s"], "p" => $triple["p"], "c" => array(), "label" => (array_key_exists('label', $triple) ? $triple["label"] : array("value" => "")), "i" => $triple["i"], "j" => $triple["j"]));
				}
				else	
					array_push($data["object_properties"]["incoming"], array("s" => $triple["s"], "p" => $triple["p"]));
			} else {
				array_push($data["object_properties"]["incoming"][count($data["object_properties"]["incoming"])-1]["c"], $triple["c"]);
			}
		}
		# data_properties
		else {
			$current_entity = "";

			if (!array_key_exists($triple["p"]["value"], $data["data_properties"]))
				$data["data_properties"][$triple["p"]["value"]] = array($triple["o"]);
			else
				array_push($data["data_properties"][$triple["p"]["value"]], $triple["o"]);
		}
	}
	
	echo json_encode($data);
?>