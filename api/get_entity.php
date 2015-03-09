<?php
	header('content-type: application/json; charset=utf-8');

	include "jena.php";

	/*	Given the URI of entity, returns the triples in which it is subject and the triples in which it is object
	*/
	if (isset($_GET["uri"])) {
		$entity = urlencode(end(split("/", $_GET["uri"])));
		$uri = "http://dbpedia.org/resource/" . $entity;
		
		$entity = str_replace("%", "%25", $entity);		

		$uri_query = "<" . urlencode("http://dbpedia.org/resource/") . $entity . ">";

		#$query = urlencode("SELECT ?s ?p ?o ?i ?j {{?g ?p ?o .OPTIONAL {?o <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?o <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.}FILTER (?g = ") . $uri_query . urlencode(" && ?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?s)}UNION{?s ?p ?g .OPTIONAL {?s <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?s <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.}FILTER (?g = ") . $uri_query . urlencode(" && ?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?o)}}");
		$query = urlencode("SELECT ?s ?p ?o ?c ?i ?j {{?g ?p ?o .OPTIONAL {?o <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?o <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.?o a ?c.FILTER (STRSTARTS(STR(?c), 'http://dbpedia.org/ontology/') && !STRSTARTS(STR(?c), 'http://dbpedia.org/ontology/Wikidata'))}FILTER (?g = ") . $uri_query . urlencode(" && ?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?s)}UNION{?s ?p ?g .OPTIONAL {?s <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?s <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.?s a ?c.FILTER (STRSTARTS(STR(?c), 'http://dbpedia.org/ontology/') && !STRSTARTS(STR(?c), 'http://dbpedia.org/ontology/Wikidata'))}FILTER (?g = ") . $uri_query . urlencode(" && ?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?o)}}");

		$query = str_replace("%3C", "<", $query);
		$query = str_replace("%3E", ">", $query);

		$result = make_query($query);
	}
	/*	Given the coordinates (i, j) of a certain entity in the map, returns the triples of the entity (both in subject and object position)
	*/
	elseif (isset($_GET["i"]) && isset($_GET["j"])) {
		$i = $_GET["i"];
		$j = $_GET["j"];

		#$query = urlencode('SELECT ?s ?p ?o ?i ?j {{?g <http://wafi.iit.cnr.it/lod/ns/atlas#i> "' . $i . '"^^<http://www.w3.org/2001/XMLSchema#integer>;<http://wafi.iit.cnr.it/lod/ns/atlas#j> "' . $j . '"^^<http://www.w3.org/2001/XMLSchema#integer>;?p ?o .OPTIONAL {?o <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?o <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.}FILTER (?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?s)}UNION{?g <http://wafi.iit.cnr.it/lod/ns/atlas#i> "' . $i . '"^^<http://www.w3.org/2001/XMLSchema#integer>;<http://wafi.iit.cnr.it/lod/ns/atlas#j> "' . $j . '"^^<http://www.w3.org/2001/XMLSchema#integer>.?s ?p ?g .OPTIONAL {?s <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?s <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.}FILTER (?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?o)}}');
		$query = urlencode('SELECT ?s ?p ?o ?c ?i ?j {{?g <http://wafi.iit.cnr.it/lod/ns/atlas#i> "' . $i . '"^^<http://www.w3.org/2001/XMLSchema#integer>;<http://wafi.iit.cnr.it/lod/ns/atlas#j> "' . $j . '"^^<http://www.w3.org/2001/XMLSchema#integer>;?p ?o .OPTIONAL {?o <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?o <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.?o a ?c.FILTER (STRSTARTS(STR(?c), "http://dbpedia.org/ontology/") && !STRSTARTS(STR(?c), "http://dbpedia.org/ontology/Wikidata"))}FILTER (?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?s)}UNION{?g <http://wafi.iit.cnr.it/lod/ns/atlas#i> "' . $i . '"^^<http://www.w3.org/2001/XMLSchema#integer>;<http://wafi.iit.cnr.it/lod/ns/atlas#j> "' . $j . '"^^<http://www.w3.org/2001/XMLSchema#integer>.?s ?p ?g .OPTIONAL {?s <http://wafi.iit.cnr.it/lod/ns/atlas#i> ?i.?s <http://wafi.iit.cnr.it/lod/ns/atlas#j> ?j.?s a ?c.FILTER (STRSTARTS(STR(?c), "http://dbpedia.org/ontology/") && !STRSTARTS(STR(?c), "http://dbpedia.org/ontology/Wikidata"))}FILTER (?p != <http://www.w3.org/2002/07/owl#sameAs>)BIND (?g AS ?o)}}');
		$result = make_query($query);

		$uri = $result["results"]["bindings"][0]["s"]["value"];
	}

	$data = array("uri" => $uri, "data_properties" => array(), "object_properties" => array("incoming" => array(), "outgoing" => array(), "itself" => array()), "types" => array());
	$current_entity = "";

	foreach ($result["results"]["bindings"] as $triple) {
		# object_properties -> itself
		if ($triple["s"]["value"] == $uri && $triple["o"]["value"] == $uri)
			array_push($data["object_properties"]["itself"], $triple["p"]);
		# object_properties -> outgoing
		else if ($triple["s"]["value"] == $uri && strpos($triple["o"]["value"], "http://dbpedia.org/resource/") > -1) {
			if ($current_entity != $triple["o"]["value"]) {
				$current_entity = $triple["o"]["value"];

				if (array_key_exists("i", $triple))
					array_push($data["object_properties"]["outgoing"], array("p" => $triple["p"], "o" => $triple["o"], "c" => array($triple["c"]), "i" => $triple["i"], "j" => $triple["j"]));
				else
					array_push($data["object_properties"]["outgoing"], array("p" => $triple["p"], "o" => $triple["o"]));
			} else {
				array_push($data["object_properties"]["outgoing"][count($data["object_properties"]["outgoing"])-1]["c"], $triple["c"]);
			}
		}
		# object_properties -> incoming
		elseif ($triple["o"]["value"] == $uri && strpos($triple["s"]["value"], "http://dbpedia.org/resource/") > -1) {
			if ($current_entity != $triple["s"]["value"]) {
				$current_entity = $triple["s"]["value"];
				
				if (array_key_exists("i", $triple))
					array_push($data["object_properties"]["incoming"], array("s" => $triple["s"], "p" => $triple["p"], "c" => array($triple["c"]), "i" => $triple["i"], "j" => $triple["j"]));
				else	
					array_push($data["object_properties"]["incoming"], array("s" => $triple["s"], "p" => $triple["p"]));
			} else {
				array_push($data["object_properties"]["incoming"][count($data["object_properties"]["incoming"])-1]["c"], $triple["c"]);
			}
		}
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