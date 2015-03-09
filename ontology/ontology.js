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
                _parse_tree(c, depth+1);
            });
            
        if(!(n.hasOwnProperty('children')) || n.children.length === 0) {
            ontology.leaves.push(n);
        }
    }
    _parse_tree(ontology.tree, 0);
}

// Returns the most specific class
ontology.get_msc = function(node, classes) {
    if (classes.length > 1) 
        classes = classes.filter(function(c) {return c.value.replace("http://dbpedia.org/ontology/", "") != node.name;});
    else
        return classes;
    
    if(node.hasOwnProperty('children'))
        node.children.forEach(function(child) {
            classes = ontology.get_msc(child, classes);
        });

    return classes;
}

// Returns a sequence of classes ordered according to the ontology hierarchy
ontology.get_ordered_classes = function(node, classes) {
    res = ontology._get_ordered_classes(node, classes, [])

    return res[1];
}

ontology._get_ordered_classes = function(node, classes, ordered_classes) {
    classes = classes.filter(function(c) {
        if (c.value.replace("http://dbpedia.org/ontology/", "") != node.name)
            return true;
        else {
            //ordered_classes.unshift(c);
            ordered_classes.push(c);
            return false;
        }
    });
    
    if(node.hasOwnProperty('children'))
        node.children.forEach(function(child) {
            res = ontology._get_ordered_classes(child, classes, ordered_classes);
            classes = res[0];
            ordered_classes = res[1];
        });

    return [classes, ordered_classes];
}

// Returns the tree node corresponding to the given class
ontology.get_node_from_class = function(klass) {
    return _index[klass];
}

}).call(this);