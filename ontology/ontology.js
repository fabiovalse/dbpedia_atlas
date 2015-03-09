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
    ontology.leaves = [];
    
    _parse_tree = function(n, depth) {
        n.depth = depth;
        ontology.nodes.push(n);
        
        // create more levels if needed
        if(ontology.levels.length <= depth)
            ontology.levels.push([]);
        
        ontology.levels[depth].push(n);
        
        if(n.hasOwnProperty('children'))
            n.children.forEach(function(c){
                c.parent = n;
                _parse_tree(c, depth+1);
            });
            
        if(!(n.hasOwnProperty('children')) || n.children.length === 0) {
            ontology.leaves.push(n);
        }
    }
    _parse_tree(ontology.tree, 0);
}

// Returns the correct path (sequence of classes ordered according to the ontology hierarchy) given a set of classes
ontology.get_path = function(classes) {
    classes = classes.map(function(c) { return c.value.replace("http://dbpedia.org/ontology/", ""); });
    
    path = [];
    classes.forEach(function(c){
        var new_path = ontology.get_path_from_class(c);
        if(new_path.length > path.length) // WARNING this works only because there are no entities with incompatible types (classes from different branches)
            path = new_path;
    });
    return path;
}

// Returns the tree node corresponding to the given class
ontology.get_node_from_class = function(klass) {
    return _index[klass];
}

// Returns the path corresponding to the given class
ontology.get_path_from_class = function(klass) {
    var node = ontology.get_node_from_class(klass);
    return ontology.get_path_from_node(node);
}

// Returns the path corresponding to the given node
ontology.get_path_from_node = function(n) {
    if(!(n.hasOwnProperty('parent')))
        return [n.name];
    
    return ontology.get_path_from_node(n.parent).concat([n.name])
}

}).call(this);