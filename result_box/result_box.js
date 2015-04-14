(function() {
window.result_box = {};

result_box.init = function(dom_selector) {
    box = d3.select(dom_selector);

    result_box.node = box;
    result_box.results = [];
}

result_box.update = function(data) {
    result_box.results = data;
    
	result_box.node.html("");
	result_box.show();

	results = result_box.node.selectAll('.entity_result')
		.data(data);

	results.enter().append('div')
		.attr('class', function(d) {return (d.in_jena) ? 'entity_result' : 'entity_result disabled';})
		.attr('id', function(d) {return d.uri;})
		.attr('title', function(d) {return (d.in_jena) ? 'Click to focus on "' + format_uri(d.uri) + '".' : 'Instance "' + format_uri(d.uri) + '" is currently out of map.';})
		.text(function(d) {return format_uri(d.uri);})
		.on('click', function(d) {
			if (d.in_jena) {
				trigger(result_box.node, 'select', {uri: this.id});

				result_box.hide();
				d3.select('#search_textbox').text("");
			}
		});
}

result_box.hide = function() {
    result_box.node.style('display', 'none');
}
result_box.show = function() {
    if(result_box.results != null && result_box.results.length > 0) {
        result_box.node.style('display', 'inline');
    }
    else {
        result_box.hide();
    }
}

}).call(this);