inset_color = null
depth_color = null

_init_modes = () ->
    ### classes ###
    
    ### WARNING this is done explicitly, to handpick colors for important regions and avoid similar color in neighboring regions ###
    classes = ["MeanOfTransportation", "SportsSeason", "Agent", "Device", "Place", "Biomolecule", "Species", "gml:_Feature", "Event", "CareerStation", "Work", "TopicalConcept", "AnatomicalStructure", "Holiday", "Food", "ChemicalSubstance", "Medicine", "Name", "CelestialBody", "SportCompetitionResult", "UnitOfWork", "GeneLocation", "Satellite", "PersonFunction", "TimePeriod", "Language", "Sales", "Colour", "EthnicGroup", "Award", "Drug", "Activity", "Currency", "SnookerWorldRanking", "Swarm", "Competition", "List"]
    colors = classes.map (c, i) ->
        # less readable classes are desaturated
        chroma = if c in ["TimePeriod", "CareerStation", "PersonFunction", "gml:_Feature", "Sales"] then 30 else 55
        return d3.hcl(15+i*30, chroma, 70)
        
    inset_color = d3.scale.ordinal()
        .domain(classes)
        .range(colors)
        
    ### depth ###
    depth_color = d3.scale.linear()
        .domain([0, ontology.levels.length-1])
        .range([d3.hcl(200, 0, 90), d3.hcl(360, 30, 30)])
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
                    
    return map