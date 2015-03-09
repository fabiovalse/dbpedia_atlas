(function() {
window.search_box = {};

search_box.init = function(dom_selector) {
    box = d3.select(dom_selector);

    search_box.node = box;
}

var get_entity_from_string = function(string) {
	trigger(search_box.node, 'search', {string: string});
};

d3.select("#search_button")
	.on("click", function() {
		get_entity_from_string(d3.select("#search_textbox").node().value)
});

d3.select("#search_textbox")
.on("keydown", function() {
	if (d3.event.keyCode == 13)
		get_entity_from_string(d3.select("#search_textbox").node().value)	
});

}).call(this);