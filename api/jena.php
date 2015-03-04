<?php
	function make_query($query) {
		return json_decode(curl_request("http://localhost:3030/dbpedia2/sparql?query=" . $query . "&output=json"), true);
	}

	function curl_request($url) {
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL, $url);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);

		return curl_exec($ch);
	}
?>