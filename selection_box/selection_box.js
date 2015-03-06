(function() {
window.selection_box = {};

var box;

selection_box.init = function(dom_selector) {
    box = d3.select(dom_selector);

    selection_box.node = box;
}

selection_box.update = function(selection) {
	/*	Sets the title = entity name
	*/
	box.select('header')
		.text(decodeURI(selection["uri"].replace("http://dbpedia.org/resource/", "").replace(/_/g, " ")) + " ");
		
	box.select('header').append('a')
		.attr('href', selection["uri"])
		.attr('target', '_blank')
		.append('img')
			.attr('id', 'dbpedia_logo')
			.attr('src', 'img/dbpedia_logo.png')
			.attr();
	box.select('header').append('a')
		.attr('href', function() {
			splitted = selection["uri"].split("/");
			return "http://en.wikipedia.org/wiki/" + splitted[splitted.length-1];
		}).attr('target', '_blank')
		.append('img')
			.attr('id', 'wikipedia_logo')
			.attr('src', 'img/wikipedia_logo.png')
			.attr();

	var filtered_types = selection["types"].filter(function(d) {return (d.value.indexOf("http://dbpedia.org/ontology/") == 0 && d.value.indexOf("http://dbpedia.org/ontology/Wikidata:") == -1);});

	var rdf_types = box.select('header').append('div')
		.attr('id', 'rdf_types')
		.selectAll('rdf_type')
		.data(filtered_types);

	console.log(get_msc(ontology, filtered_types));

	rdf_types.enter().append('span')
		.attr('class', 'rdf_type')
		.attr('title', function(d) {return d.value;})
		.html(function(d, i) {
			return (i < filtered_types.length-1) ? format_uri(d.value) + " - " : format_uri(d.value);
		});

	var section = box.select('section');
	section.selectAll("*").remove();

	/*	Data properties
	*/
	data_properties = Object.keys(selection["data_properties"]).map(function(k){ var o = {}; o[k] = selection["data_properties"][k]; return o;});

	var data_property = section
		.append('div')
		.attr('class', 'data_box')
		.selectAll('.data_property')
		.data(data_properties.sort(sort_data_prop));

	data_property.enter().append('div')
		.attr('class', 'data_property')
		.html(function(d) {
			for (key in d) {
				return (d[key][0]["type"] == "uri") ? "<span class='predicate' title='" + key + "'>" + format_uri(key) + "&nbsp;&#8594; </span><span><a href='" + d[key][0]["value"] + "' target='_blank'>" + d[key][0]["value"] + "</a></span>" : "<span class='predicate' title='" + key + "'>" + format_uri(key) + "&nbsp;&#8594; </span><span>" + d[key][0]["value"] + "</span>";
			}
		});

	/*	Object properties OUTGOING
	*/
	var data = selection["object_properties"]["outgoing"].sort(sort_obj_prop);
	var data_outgoing = [];
	var current_p = "";

	data.forEach(function(d) {
		if (current_p != d["p"]["value"]) {
			data_outgoing.push({"p": d["p"], "o": [d["o"]]});
			current_p = d["p"]["value"];
		}
		else {
			data_outgoing.forEach(function(d2) {
				if (d["p"]["value"] == d2["p"]["value"])
					d2["o"].push(d["o"]);
			});
		}
	});

	var outgoing = section
		.append('div')
		.attr('class', 'data_box')
		.selectAll('.outgoing')
		.data(data_outgoing);

	outgoing.enter().append('div')
		.attr('class', 'outgoing')
		.html(function(d) {
			html = "<table><tr><td class='predicate' title='" + d["p"]["value"] +  "' rowspan='" + d["o"].length + "'>" + format_uri(d["p"]["value"]) + "&nbsp;&#8594; </td>";
			d["o"].forEach(function(o, i) {
				if (i > 0)
					html += "<tr>";

				html += "<td class='object_uri' title='" + o["value"] + "' onclick='trigger(selection_box.node, \"select\", {uri: \"" + o["value"] + "\"})'>" + format_uri(o["value"]) + "</td></tr>";
			});
			return html + "</table>";
		});

	/*	Object properties INCOMING
	*/
	data = selection["object_properties"]["incoming"].sort(sort_obj_prop);
	var data_incoming = [];
	current_p = "";

	data.forEach(function(d) {
		if (current_p != d["p"]["value"]) {
			data_incoming.push({"p": d["p"], "s": [d["s"]]});
			current_p = d["p"]["value"];
		}
		else {
			data_incoming.forEach(function(d2) {
				if (d["p"]["value"] == d2["p"]["value"])
					d2["s"].push(d["s"]);
			});
		}
	});

	var incoming = section
		.append('div')
		.attr('class', 'data_box')
		.selectAll('.incoming')
		.data(data_incoming);

	incoming.enter().append('div')
		.attr('class', 'incoming')
		.html(function(d) {
			html = "<table>";

			d["s"].forEach(function(s, i) {
				html += "<tr><td class='object_uri right_text' title='" + s["value"] + "' onclick='trigger(selection_box.node, \"select\", {uri: \"" + s["value"] + "\"})'>" + format_uri(s["value"]) + "</td>";

				if (i == 0)
					html += "<td class='predicate right_text' title='" + d["p"]["value"] +  "' rowspan='" + d["s"].length + "'>&nbsp;&#8592; " + format_uri(d["p"]["value"]) + "</td>";
				
				html += "</tr>";
			});

			return html + "</table>";
		});
}

var sort_data_prop = function (a, b) {
	if (Object.keys(a)[0] > Object.keys(b)[0])
		return 1;
	if (Object.keys(a)[0] < Object.keys(b)[0])
    	return -1;
  	return 0;
}

var sort_obj_prop = function (a, b) {
	if (a["p"]["value"] > b["p"]["value"])
		return 1;
	if (a["p"]["value"] < b["p"]["value"])
    	return -1;
  	return 0;
}

}).call(this);
