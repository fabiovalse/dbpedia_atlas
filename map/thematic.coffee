inset_color = null
depth_color = null
triple_density_color = null
obj_props_density_color = null
data_props_density_color = null

_init_modes = () ->
    ### classes ###

    ### WARNING this is done explicitly, to handpick colors for important regions and avoid similar color in neighboring regions ###
    classes = [
        "http://dbpedia.org/ontology/MeanOfTransportation",
        "http://dbpedia.org/ontology/SportsSeason",
        "http://dbpedia.org/ontology/Agent",
        "http://dbpedia.org/ontology/Device",
        "http://dbpedia.org/ontology/Place",
        "http://dbpedia.org/ontology/Biomolecule",
        "http://dbpedia.org/ontology/Species",
        "http://www.opengis.net/gml/_Feature",
        "http://dbpedia.org/ontology/Event",
        "http://dbpedia.org/ontology/CareerStation",
        "http://dbpedia.org/ontology/Work",
        "http://dbpedia.org/ontology/TopicalConcept",
        "http://dbpedia.org/ontology/AnatomicalStructure",
        "http://dbpedia.org/ontology/Holiday",
        "http://dbpedia.org/ontology/Food",
        "http://dbpedia.org/ontology/ChemicalSubstance",
        "http://dbpedia.org/ontology/Medicine",
        "http://dbpedia.org/ontology/Name",
        "http://dbpedia.org/ontology/CelestialBody",
        "http://dbpedia.org/ontology/SportCompetitionResult",
        "http://dbpedia.org/ontology/UnitOfWork",
        "http://dbpedia.org/ontology/GeneLocation",
        "http://dbpedia.org/ontology/Satellite",
        "http://dbpedia.org/ontology/PersonFunction",
        "http://dbpedia.org/ontology/TimePeriod",
        "http://dbpedia.org/ontology/Language",
        "http://dbpedia.org/ontology/Sales",
        "http://dbpedia.org/ontology/Colour",
        "http://dbpedia.org/ontology/EthnicGroup",
        "http://dbpedia.org/ontology/Award",
        "http://dbpedia.org/ontology/Drug",
        "http://dbpedia.org/ontology/Activity",
        "http://dbpedia.org/ontology/Currency",
        "http://dbpedia.org/ontology/SnookerWorldRanking",
        "http://dbpedia.org/ontology/Swarm",
        "http://dbpedia.org/ontology/Competition",
        "http://dbpedia.org/ontology/List"
    ]
    colors = classes.map (c, i) ->
        # less readable classes are desaturated
        chroma = if c in [
            "http://dbpedia.org/ontology/TimePeriod",
            "http://dbpedia.org/ontology/CareerStation",
            "http://dbpedia.org/ontology/PersonFunction",
            "http://www.opengis.net/gml/_Feature",
            "http://dbpedia.org/ontology/Sales"] then 30 else 55
        return d3.hcl(15+i*30, chroma, 70)

    inset_color = d3.scale.ordinal()
        .domain(classes)
        .range(colors)

    ### depth ###
    depth_color = d3.scale.linear()
        .domain([0, ontology.levels.length-1])
        .range([d3.hcl(200, 0, 90), d3.hcl(360, 30, 30)])
        .interpolate(d3.interpolateHcl)

    ### triple density ###
    triple_density_color = d3.scale.linear()
        .domain([0, d3.max(map.leaf_regions, (f) -> f.properties.node.stats.triple_density)])
        .range([d3.hcl(100, 0, 90), d3.hcl(260, 30, 30)])
        .interpolate(d3.interpolateHcl)

    ### object properties density ###
    obj_props_density_color = d3.scale.linear()
        .domain([0, d3.max(map.leaf_regions, (f) -> f.properties.node.stats.obj_props_density)])
        .range([d3.hcl(0, 0, 90), d3.hcl(160, 30, 30)])
        .interpolate(d3.interpolateHcl)

    ### data properties density ###
    data_props_density_color = d3.scale.linear()
        .domain([0, d3.max(map.leaf_regions, (f) -> f.properties.node.stats.data_props_density)])
        .range([d3.hcl(50, 0, 90), d3.hcl(210, 30, 30)])
        .interpolate(d3.interpolateHcl)

map.mode = (requested_mode) ->
    switch requested_mode
        when 'classes'
            land_layer.selectAll('.leaf_region')
                .attr
                    fill: '#D8D6CC'

            land_layer.selectAll('.high_region')
                .attr
                    stroke: (n) -> inset_color(n.name)
                    'stroke-width': '12px'

        when 'depth'
            land_layer.selectAll('.leaf_region')
                .attr
                    fill: (r) -> depth_color(r.properties.node.depth)

            land_layer.selectAll('.high_region')
                .attr
                    'stroke-width': 0

        when 'triple_density'
            land_layer.selectAll('.leaf_region')
                .attr
                    fill: (r) -> triple_density_color(r.properties.node.stats.triple_density)

            land_layer.selectAll('.high_region')
                .attr
                    'stroke-width': 0

        when 'obj_props_density'
            land_layer.selectAll('.leaf_region')
                .attr
                    fill: (r) -> obj_props_density_color(r.properties.node.stats.obj_props_density)

            land_layer.selectAll('.high_region')
                .attr
                    'stroke-width': 0

        when 'data_props_density'
            land_layer.selectAll('.leaf_region')
                .attr
                    fill: (r) -> data_props_density_color(r.properties.node.stats.data_props_density)

            land_layer.selectAll('.high_region')
                .attr
                    'stroke-width': 0
    return map
