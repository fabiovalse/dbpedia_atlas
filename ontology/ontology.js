(function() {
window.ontology = {}

var _index = {}

ontology.init = function(data) {
    ontology.tree = data;
    
    // Create support structures for using the tree
    _create_index = function(n) {
        _index[n.name] = n;
        if(n.hasOwnProperty('children'))
            n.children.forEach(function(c){
                _create_index(c);
            });
    }
    _create_index(ontology.tree);
    
    
    ontology.levels = [];
    ontology.nodes = [];
    
    _assign_depth = function(n, depth) {
        n.depth = depth;
        ontology.nodes.push(n);
        
        // create more levels if needed
        if(ontology.levels.length <= depth)
            ontology.levels.push([]);
        
        ontology.levels[depth].push(n);
        
        if(n.hasOwnProperty('children'))
            n.children.forEach(function(c){
                _assign_depth(c, depth+1);
            });
    }
    _assign_depth(ontology.tree, 0);
}

// Returns the most specific class
ontology.get_msc = function(node, classes) {
    if (classes.length > 1) 
        classes = classes.filter(function(c) {return c.value.replace("http://dbpedia.org/ontology/", "") != node.name;});
    else
        return classes;
    
    if(n.hasOwnProperty('children'))
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