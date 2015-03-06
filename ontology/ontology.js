(function() {
window.ontology = {}

ontology.init = function(data) {
    ontology.tree = data;
}

// Returns the most specific class
ontology.get_msc = function(node, classes) {
    if (classes.length > 1) 
        classes = classes.filter(function(c) {return c.value.replace("http://dbpedia.org/ontology/", "") != node.name;});
    else
        return classes;

    node.children.forEach(function(child) {
        classes = ontology.get_msc(child, classes);
    });

    return classes;
}

}).call(this);