map.preprocess = (data) ->
    features = topojson.feature(data, data.objects.leaf_regions).features
    geometries = data.objects.leaf_regions.geometries
    
    ### parse paths into arrays, and extract the class of each leaf region ###
    features.forEach (f) ->
        f.properties.path = JSON.parse(f.properties.path)
        f.properties.class = f.properties.path[f.properties.path.length-1]
        
    ### presimplify the topology (compute the effective area (z) of each point) ###
    topojson.presimplify(data)
    
    ### store all leaf_regions into the ontology tree ###
    features.forEach (f) ->
        ontology.get_node_from_class(f.properties.class).leaf_region = f
        
    ### compute merged regions from leaf regions ###
    _merge = (n, depth) ->
        n.merged_region = topojson.merge(data, geometries.filter (g) -> g.properties.path.length > depth and g.properties.path[depth] is n.name)
        
        if n.children?
            n.children.forEach (c) -> _merge(c, depth+1)
        
    _merge(ontology.tree, 0)