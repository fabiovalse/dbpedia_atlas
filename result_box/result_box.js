(function() {
window.result_box = {};

result_box.init = function(dom_selector) {
    box = d3.select(dom_selector);

    result_box.node = box;
}

result_box.update = function(selection) {
	console.log(selection);
}

}).call(this);
