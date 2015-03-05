(function() {
window.selection_box = {};

var box;

selection_box.init = function(dom_selector) {
    box = d3.select(dom_selector);

    selection_box.node = box;
}

selection_box.update = function(selection) {
	console.log(selection);

	/*	Sets the title = entity name
	*/
	box.select('header')
		.text(decodeURI(selection["uri"].replace("http://dbpedia.org/resource/", "").replace(/_/g, " ")));

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
				return "<span class='predicate' title='" + key + "'>" + format_uri(key) + ":</span> <span class='object'>" + d[key][0]["value"] + "</span>";
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
			html = "<table><tr><td class='predicate' title='" + d["p"]["value"] +  "' rowspan='" + d["o"].length + "'>" + format_uri(d["p"]["value"]) + ":</td>";
			d["o"].forEach(function(o, i) {
				if (i > 0)
					html += "<tr>";

				html += "<td title='" + o["value"] + "' onclick='trigger(selection_box.node, \"select\", {uri: \"" + o["value"] + "\"})'>" + format_uri(o["value"]) + "</td></tr>";
			});
			return html + "</table>";
			//return "<span class='predicate' title='" + d["p"]["value"] +  "'>" + format_uri(d["p"]["value"]) + ":</span> <span class='object' title='" + d["o"]["value"] + "'>" + format_uri(d["o"]["value"]) + "</span>";
		});

	/*	Object properties INCOMING
	*/
	var incoming = section
		.append('div')
		.attr('class', 'data_box')
		.selectAll('.incoming')
		.data(selection["object_properties"]["incoming"].sort(sort_obj_prop));

	incoming.enter().append('div');

	incoming.append('text')
		.attr('class', 'incoming')
		.html(function(d) {
			return "<span class='object' title='" + d["s"]["value"] + "'>" + format_uri(d["s"]["value"]) + ":</span> <span class='predicate' title='" + d["p"]["value"] +  "'>" + format_uri(d["p"]["value"]) + "</span>";
		});
}

var format_uri = function(key) {
	var newKey = "";
	var flag = false;

	uriKey = key;

	splittedKey = key.replace(/_/g, " ").split("/");
	key = splittedKey[splittedKey.length-1];

	if (key.indexOf("#") != -1) {
		key = key.substring(key.indexOf("#")+1);
	}

	for (i in key) {
		if (!flag && key.charAt(i) === key.charAt(i).toUpperCase()) {
			newKey += " ";
			newKey += key.charAt(i);
			flag = true;
		} else {
			newKey += key.charAt(i);
			flag = false;
		}
	}

	return (newKey.charAt(0).toUpperCase() + newKey.slice(1));
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
