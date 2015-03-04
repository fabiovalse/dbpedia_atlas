(function() {
window.selection_box = {};

var box;

selection_box.init = function(dom_selector) {
    box = d3.select(dom_selector);
}

}).call(this);
