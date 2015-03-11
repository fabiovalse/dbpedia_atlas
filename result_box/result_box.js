(function() {
window.result_box = {};

result_box.init = function(dom_selector) {
    box = d3.select(dom_selector);

    result_box.node = box;
}

result_box.update = function(selection) {
	result_box.node.html("");
	result_box.node.style("display", "inline");

	var results = result_box.node.selectAll('.entity_result')
		.data(selection);

	results.enter().append('div')
		.attr('class', function(d) {return (d.in_jena) ? 'entity_result' : 'entity_result disabled';})
		.attr('id', function(d) {return d.uri;})
		.attr('title', function(d) {return (d.in_jena) ? d.uri : d.uri + ' currently out of map.';})
		.text(function(d) {return format_uri(d.uri);})
		.on('click', function(d) {
			if (d.in_jena) {
				trigger(result_box.node, 'select', {uri: this.id});

				result_box.node.style("display", "none");
				d3.select('#search_textbox').text("");
			}
		});
}

}).call(this);