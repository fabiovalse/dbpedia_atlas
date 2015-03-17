_preprocess = (data, untyped_data, stats_data) ->
    map.leaf_regions = topojson.feature(data, data.objects.leaf_regions).features
    geometries = data.objects.leaf_regions.geometries

    ### parse paths into arrays, and extract the class of each leaf region ###
    map.leaf_regions.forEach (f) ->
        f.properties.path = JSON.parse(f.properties.path)
        f.properties.class = f.properties.path[f.properties.path.length-1]

    ### presimplify the topologies (compute the effective area (z) of each point) ###
    topojson.presimplify(data)
    topojson.presimplify(untyped_data)

    ### store all leaf_regions into the ontology tree, and store each node within the feature's properties ###
    map.leaf_regions.forEach (f) ->
        n = ontology.get_node_from_class(f.properties.class)
        n.leaf_region = f
        f.properties.node = n

    ### compute merged regions from leaf regions ###
    _merge = (n, depth) ->
        n.merged_region = topojson.merge(data, geometries.filter (g) -> g.properties.path.length > depth and g.properties.path[depth] is n.name)

        if n.children?
            n.children.forEach (c) -> _merge(c, depth+1)

    _merge(ontology.tree, 0)

    ### compute all region centroids ###
    ontology.nodes.forEach (n) ->
        [n.x, n.y] = path_generator.centroid n.merged_region

    ### compute all region areas ###
    ontology.nodes.forEach (n) ->
        n.area = path_generator.area n.merged_region

    ### create a stats index ###
    _stats = {}
    stats_data.forEach (s) -> _stats[s.class] = s

    ### add stats to each leaf region ###
    map.leaf_regions.forEach (f) ->
        f.properties.node.stats = _stats[f.properties.node.name]

        console.error "Class not found in statistics data: #{f.properties.node.name}" if not f.properties.node.stats?

    ### compute additional stats ###
    map.leaf_regions.forEach (f) ->
        f.properties.node.stats.triple_density = f.properties.node.stats.triple_count / f.properties.node.leaf_count
        f.properties.node.stats.obj_props_density = f.properties.node.stats.obj_props_count / f.properties.node.leaf_count
        f.properties.node.stats.data_props_density = f.properties.node.stats.data_props_count / f.properties.node.leaf_count

    ### define readable, plural, multiline labels for level one regions ###
    _readable_labels =
        'http://dbpedia.org/ontology/Place': ['Places']
        'http://dbpedia.org/ontology/Agent': ['Agents']
        'http://dbpedia.org/ontology/Event': ['Events']
        'http://dbpedia.org/ontology/Species': ['Species']
        'http://dbpedia.org/ontology/Work': ['Works']
        'http://dbpedia.org/ontology/SportsSeason': ['Sports', 'Seasons']
        'http://dbpedia.org/ontology/UnitOfWork': ['Units of', 'Work']
        'http://dbpedia.org/ontology/TopicalConcept': ['Topical', 'Concepts']
        'http://dbpedia.org/ontology/Biomolecule': ['Biomolecules']
        'http://dbpedia.org/ontology/Activity': ['Activities']
        'http://dbpedia.org/ontology/Food': ['Food']
        'http://dbpedia.org/ontology/MeanOfTransportation': ['Means of', 'Transportation']
        'http://dbpedia.org/ontology/Device': ['Devices']
        'http://dbpedia.org/ontology/CelestialBody': ['Celestial', 'Bodies']
        'http://dbpedia.org/ontology/ChemicalSubstance': ['Chemical', 'Substances']
        'http://dbpedia.org/ontology/Medicine': ['Diseases'] # FIXME why are they called Medicine?
        'http://dbpedia.org/ontology/TimePeriod': ['Time', 'Periods']
        'http://dbpedia.org/ontology/Satellite': ['Satellites']
        'http://dbpedia.org/ontology/SportCompetitionResult': ['Sport', 'Competition', 'Results']
        'http://dbpedia.org/ontology/AnatomicalStructure': ['Anatomical', 'Structures']
        'http://dbpedia.org/ontology/GeneLocation': ['Gene', 'Locations']
        'http://dbpedia.org/ontology/CareerStation': ['Career', 'Stations']
        'http://dbpedia.org/ontology/PersonFunction': ['Person', 'Functions']
        'http://www.opengis.net/gml/_Feature': ['gml:feature']
        'http://dbpedia.org/ontology/Language': ['Languages']
        'http://dbpedia.org/ontology/Sales': ['Sales']
        'http://dbpedia.org/ontology/Drug': ['Drugs']
        'http://dbpedia.org/ontology/EthnicGroup': ['Ethnic', 'Groups']
        'http://dbpedia.org/ontology/Award': ['Awards']
        'http://dbpedia.org/ontology/Colour': ['Colours']
        'http://dbpedia.org/ontology/Holiday': ['Holidays']
        'http://dbpedia.org/ontology/Currency': ['Currencies']
        'http://dbpedia.org/ontology/SnookerWorldRanking': ['Snooker','World','Rankings']
        'http://dbpedia.org/ontology/Swarm': ['Swarms']
        'http://dbpedia.org/ontology/Competition': ['Competitions']
        'http://dbpedia.org/ontology/List': ['Lists']
        'http://dbpedia.org/ontology/Name': ['Names']

    ontology.levels[1].forEach (n) ->
        n.readable_label = _readable_labels[n.name]

_preprocess_selection = (selection) ->
    ### compute cartesian coordinates ###
    [selection.x, selection.y] = _ij_to_xy(selection.i, selection.j)

    ### compute selection parent, if any ###
    if selection.path.length > 0
        selection.parent = ontology.get_node_from_class(selection.path[selection.path.length-1])
    else
        selection.parent = null

    ### extract relational links ###
    ### FIXME links to self are currently ignored ###
    selection.relations = []

    ### outgoing links ###
    selection.object_properties.outgoing.forEach (t) ->
        if 'i' of t and 'j' of t
            [ox, oy] = _ij_to_xy(t.i.value, t.j.value)
            path = ontology.get_path(t.c)

            selection.relations.push {
                source: selection,
                predicate: t.p.value,
                target: {
                    uri: t.o.value,
                    i: t.i.value,
                    j: t.j.value,
                    x: ox,
                    y: oy,
                    parent: if path.length > 0 then ontology.get_node_from_class(path[path.length-1]) else null
                }
            }
        else
            console.error('Link to out-of-map entity: ' + t.o.value)

    ### incoming links ###
    selection.object_properties.incoming.forEach (t) ->
        if 'i' of t and 'j' of t
            [sx, sy] = _ij_to_xy(t.i.value, t.j.value)
            path = ontology.get_path(t.c)

            selection.relations.push {
                source: {
                    uri: t.s.value,
                    i: t.i.value,
                    j: t.j.value,
                    x: sx,
                    y: sy,
                    parent: if path.length > 0 then ontology.get_node_from_class(path[path.length-1]) else null
                },
                predicate: t.p.value,
                target: selection
            }
        else
            console.error('Link from out-of-map entity: ' + t.s.value)

    ### pointers relative to current selection ###
    selection.relations.forEach (r) ->
        if r.source is selection
            r.start = r.source
            r.end = r.target
        else
            r.start = r.target
            r.end = r.source
