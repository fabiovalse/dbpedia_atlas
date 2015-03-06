(function() {
window.result_box = {};

result_box.init = function(dom_selector) {
    box = d3.select(dom_selector);

    result_box.node = box;
}

result_box.update = function(selection) {
	result_box.node.html("");
	result_box.node.style("display", "inline");

	/*html = "";
	selection.forEach(function(d) { html += "<div class='entity_result' title='" + d.uri + "'>" + format_uri(d.uri) + "</div>";});
	result_box.node.html(html);*/

	var results = result_box.node.selectAll('.entity_result')
		.data(selection);

	results.enter().append('div')
		.attr('class', 'entity_result')
		.attr('id', function(d) {return d.uri;})
		.text(function(d) {return format_uri(d.uri);})
		.on('click', function() {
			trigger(result_box.node, 'select', {uri: this.id});

			result_box.node.style("display", "none");
			search_box.node.text("");
		});
}

}).call(this);
