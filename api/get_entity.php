<?php
	header('content-type: application/json; charset=utf-8');

	include "jena.php";

	/*	Given the URI of entity, returns the triples in which it is subject and the triples in which it is object
	*/
	if (isset($_GET["uri"])) {
		$uri = $_GET["uri"];

		#$query = urlencode("SELECT ?s ?p ?o {{?g ?p ?o .FILTER (?g = <" . $uri . "> && ?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?s)}UNION{?s ?p ?g .FILTER (?g = <" . $uri . "> && ?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?o)}}");
		$query = urlencode("SELECT ?s ?p ?o ?i ?j {{?g ?p ?o .OPTIONAL {?o <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?o <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.}FILTER (?g = <" . $uri . "> && ?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?s)}UNION{?s ?p ?g .OPTIONAL {?s <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?s <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.}FILTER (?g = <" . $uri . "> && ?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?o)}}");
		$result = make_query($query);
	}
	/*	Given the coordinates (i, j) of a certain entity in the map, returns the triples of the entity (both in subject and object position)
	*/
	elseif (isset($_GET["i"]) && isset($_GET["j"])) {
		$i = $_GET["i"];
		$j = $_GET["j"];

		#$query = urlencode('SELECT ?s ?p ?o {{?g <http://wafi.iit.cnr.it/lod/ns/atlas#i> "' . $i . '"^^<http://www.w3.org/2001/XMLSchema#integer>;<http://wafi.iit.cnr.it/lod/ns/atlas#j> "' . $j . '"^^<http://www.w3.org/2001/XMLSchema#integer>;?p ?o .FILTER (?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?s)}UNION{?g <http://wafi.iit.cnr.it/lod/ns/atlas#i> "' . $i . '"^^<http://www.w3.org/2001/XMLSchema#integer>;<http://wafi.iit.cnr.it/lod/ns/atlas#j> "' . $j . '"^^<http://www.w3.org/2001/XMLSchema#integer>.?s ?p ?g .FILTER (?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?o)}}');
		$query = urlencode('SELECT ?s ?p ?o ?i ?j {{?g <http://wafi.iit.cnr.it/lod/ns/atlas#i> "' . $i . '"^^<http://www.w3.org/2001/XMLSchema#integer>;<http://wafi.iit.cnr.it/lod/ns/atlas#j> "' . $j . '"^^<http://www.w3.org/2001/XMLSchema#integer>;?p ?o .OPTIONAL {?o <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?o <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.}FILTER (?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?s)}UNION{?g <http://wafi.iit.cnr.it/lod/ns/atlas#i> "' . $i . '"^^<http://www.w3.org/2001/XMLSchema#integer>;<http://wafi.iit.cnr.it/lod/ns/atlas#j> "' . $j . '"^^<http://www.w3.org/2001/XMLSchema#integer>.?s ?p ?g .OPTIONAL {?s <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?s <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.}FILTER (?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?o)}}');
		$result = make_query($query);

		$uri = $result["results"]["bindings"][0]["s"]["value"];
	}

	$data = array("uri" => $uri, "data_properties" => array(), "object_properties" => array("incoming" => array(), "outgoing" => array(), "itself" => array()), "types" => array());

	foreach ($result["results"]["bindings"] as $triple) {
		# object_properties -> itself
		if ($triple["s"]["value"] == $uri && $triple["o"]["value"] == $uri)
			array_push($data["object_properties"]["itself"], $triple["p"]);
		# object_properties -> outgoing
		else if ($triple["s"]["value"] == $uri && strpos($triple["o"]["value"], "http://dbpedia.org/resource/") > -1) {
			if (array_key_exists("i", $triple))
				array_push($data["object_properties"]["outgoing"], array("p" => $triple["p"], "o" => $triple["o"], "i" => $triple["i"], "j" => $triple["j"]));
			else
				array_push($data["object_properties"]["outgoing"], array("p" => $triple["p"], "o" => $triple["o"]));
		}
		# object_properties -> incoming
		elseif ($triple["o"]["value"] == $uri && strpos($triple["s"]["value"], "http://dbpedia.org/resource/") > -1)
			if (array_key_exists("i", $triple))
				array_push($data["object_properties"]["incoming"], array("s" => $triple["s"], "p" => $triple["p"], "i" => $triple["i"], "j" => $triple["j"]));
			else	
				array_push($data["object_properties"]["incoming"], array("s" => $triple["s"], "p" => $triple["p"]));
		# data_properties
		elseif ($triple["p"]["value"] == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
			array_push($data["types"], $triple["o"]);
		else {
			if (!array_key_exists($triple["p"]["value"], $data["data_properties"]))
				$data["data_properties"][$triple["p"]["value"]] = array($triple["o"]);
			else
				array_push($data["data_properties"][$triple["p"]["value"]], $triple["o"]);
		}
	}

	echo json_encode($data);
?>