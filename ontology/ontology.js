(function() {
window.ontology = {}

var _index = {}
_create_index = function(n) {
    _index[n.name] = n;
    n.children.forEach(function(c){
        _create_index(c);
    });
}

ontology.init = function(data) {
    ontology.tree = data;
    
    _create_index(ontology.tree);
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

// Returns the tree node corresponding to the given class
ontology.get_node_from_class = function(klass) {
    return _index[klass];
}

}).call(this);