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
    
    ### compute all region areas ###
    ontology.nodes.forEach (n) ->
        n.area = path_generator.area n.merged_region
        
    ### define readable, plural, multiline labels for level one regions ###
    _readable_labels =
        'Place': ['Places']
        'Agent': ['Agents']
        'Event': ['Events']
        'Species': ['Species']
        'Work': ['Works']
        'SportsSeason': ['Sports', 'Seasons']
        'UnitOfWork': ['Units of', 'Work']
        'TopicalConcept': ['Topical', 'Concepts']
        'Biomolecule': ['Biomolecules']
        'Activity': ['Activities']
        'Food': ['Food']
        'MeanOfTransportation': ['Means of', 'Transportation']
        'Device': ['Devices']
        'CelestialBody': ['Celestial', 'Bodies']
        'ChemicalSubstance': ['Chemical', 'Substances']
        'Medicine': ['Diseases'] # FIXME why are they called Medicine?
        'TimePeriod': ['Time', 'Periods']
        'Satellite': ['Satellites']
        'SportCompetitionResult': ['Sport', 'Competition', 'Results']
        'AnatomicalStructure': ['Anatomical', 'Structures']
        'GeneLocation': ['Gene', 'Locations']
        'CareerStation': ['Career', 'Stations']
        'PersonFunction': ['Person', 'Functions']
        'gml:_Feature': ['gml:feature']
        'Language': ['Languages']
        'Sales': ['Sales']
        'Drug': ['Drugs']
        'EthnicGroup': ['Ethnic', 'Groups']
        'Award': ['Awards']
        'Colour': ['Colours']
        'Holiday': ['Holidays']
        'Currency': ['Currencies']
        'SnookerWorldRanking': ['Snooker','World','Rankings']
        'Swarm': ['Swarms']
        'Competition': ['Competitions']
        'List': ['Lists']
        'Name': ['Names']
        
    ontology.levels[1].forEach (n) ->
        n.readable_label = _readable_labels[n.name]
        