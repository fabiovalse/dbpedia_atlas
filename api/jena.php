<?php
	function make_query($query) {
		return json_decode(curl_request("http://localhost:3030/dbpedia3/sparql?query=" . $query . "&output=json"), true);
	}

	function curl_request($url) {
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL, $url);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
		#curl_setopt($ch, CURLOPT_HTTPHEADER, "Accept: application/json");

		return curl_exec($ch);
	}
?>