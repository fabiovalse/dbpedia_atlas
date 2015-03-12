window.map = {}

### globals ###
svg = null
defs = null
zoom_layer = null
vis = null
map_layer = null
cursor = null
sea_layer = null
land_layer = null
cities_layer = null
relations_layer = null
region_labels_layer = null

SIZE = 100
CELL_RADIUS = 0.02
sin30 = Math.sin(Math.PI/6)
cos30 = Math.cos(Math.PI/6)

map.init = (dom_node) ->
    svg = d3.select(dom_node)
    map.node = svg
    
    svg
        .attr
            viewBox: "#{-SIZE/2} #{-SIZE/2} #{SIZE} #{SIZE}"
            
    defs = svg.append('defs')
    
    ### define sea pattern ###
    sea_pattern = defs.append('pattern')
        .attr
            id: 'sea_pattern'
            x: 0
            y: 0
            width: 30
            height: 30
            patternUnits: 'userSpaceOnUse'
            
    sea_pattern.append('path')
        .attr
            d: 'M0 0.5 L 10 0.5'
            stroke: 'rgba(30,0,0,0.4)'
            'stroke-width': '0.3'
            
    sea_pattern.append('path')
        .attr
            d: 'M15 15.5 L 25 15.5'
            stroke: 'rgba(30,0,0,0.4)'
            'stroke-width': '0.3'
            
    ### init test ###
    svg.append('rect')
        .attr
            class: 'debug'
            x: -SIZE/2
            y: -SIZE/2
            width: SIZE
            height: SIZE
            stroke: 'red'
            
    bcr = svg.node().getBoundingClientRect()
    
    u_px_ratio = SIZE/Math.min(bcr.width, bcr.height)
    
    bluerect = svg.append('rect')
        .attr
            class: 'debug'
            x: -bcr.width/2*u_px_ratio
            y: -bcr.height/2*u_px_ratio
            width: bcr.width*u_px_ratio
            height: bcr.height*u_px_ratio
            stroke: 'blue'
            
    d3.select(window).on 'resize', () ->
        bcr = svg.node().getBoundingClientRect()
        
        u_px_ratio = SIZE/Math.min(bcr.width, bcr.height)
        
        bluerect.attr
            x: -bcr.width/2*u_px_ratio
            y: -bcr.height/2*u_px_ratio
            width: bcr.width*u_px_ratio
            height: bcr.height*u_px_ratio
            stroke: 'green'
            
    ### END init test ###
    
    
    ### ZOOM and PAN ###
    zoom_layer = svg.append('g')
    svg.call d3.behavior.zoom()
        .scaleExtent([0.6, 120])
        .on 'zoom', () ->
            zoom_layer.attr
                transform: "translate(#{d3.event.translate})scale(#{d3.event.scale})"
                
            ### semantic zooming ###
            zoom_layer.selectAll('.label')
                .attr
                    transform: "scale(#{1/d3.event.scale}) rotate(60)"
                
            ### LOD ###
            _update_lod(d3.event.scale)
            
    vis = zoom_layer.append('g')
        .attr
            transform: 'translate(22,-28) rotate(-60)'
        
    map_layer = vis.append('g')
    sea_layer = map_layer.append('g')
    land_layer = map_layer.append('g')
    relations_layer = map_layer.append('g')
    cities_layer = map_layer.append('g')
    region_labels_layer = map_layer.append('g')
    
    ### cursor ###
    cursor = vis.append('path')
        .attr
            class: 'cursor hex_cell'
            d: (r) -> _hex_path
        .style
            display: 'none'
            
    land_layer.on 'click', () ->
        # disable cursor movement when panning
        # see https://github.com/mbostock/d3/wiki/Drag-Behavior
        return if d3.event.defaultPrevented
        
        ### move the cursor to provide feedback ###
        h = _get_hexagon(d3.mouse(this))
        _move_cursor(h[0], h[1])
        
        ### trigger a selection event ###
        trigger map.node, 'select', {i: h[0], j: h[1]}
        
        
### custom projection to make hexagons appear regular (y axis is also flipped) ###
dx = CELL_RADIUS * 2 * Math.sin(Math.PI / 3)
dy = CELL_RADIUS * 1.5

SIMPLIFICATION = 400

path_generator = d3.geo.path()
    .projection d3.geo.transform({
        point: (x,y,z) ->
            ### Level of Detail ###
            if z >= SIMPLIFICATION
                this.stream.point(x * dx / 2, -(y - (2 - (y & 1)) / 3) * dy / 2)
    })
    
map.load = (data, stats_data) ->
    _preprocess(data, stats_data)
    _init_modes()
    
    ### fill the sea ###
    ### cover the sea with a pattern ###
    sea_layer.append('rect')
        .attr
            id: 'sea'
            width: 10000
            height: 10000
            x: -5000
            y: -5000
            fill: 'url(#sea_pattern)'
            transform: 'scale(0.05) rotate(60)'
    
    ### define the level zero region (the land) ###
    defs.append('path')
        .datum(topojson.mesh(data, data.objects.leaf_regions, (a,b) -> a is b))
        .attr('id', 'land')
        .attr('d', path_generator)
    
    ### faux land glow (using filters takes too much resources) ###
    sea_layer.append('use')
        .attr('class', 'land-glow-outer')
        .attr('xlink:href', '#land')

    sea_layer.append('use')
        .attr('class', 'land-glow-inner')
        .attr('xlink:href', '#land')
        
    ### actual regions ###
    land_layer.selectAll('.leaf_region')
        .data(topojson.feature(data, data.objects.leaf_regions).features)
      .enter().append('path')
        .attr
            class: 'leaf_region'
            d: path_generator
            
    ### draw the leaf regions boundaries ###
    land_layer.append('path')
        .datum(topojson.mesh(data, data.objects.leaf_regions, (a,b) -> a isnt b and a.properties.path[1] is b.properties.path[1]))
        .attr('d', path_generator)
        .attr('class', 'boundary low')
        .style('stroke-width', '0.5px')
        
    ### draw the level two boundaries ###
    land_layer.append('path')
        .datum(topojson.mesh(data, data.objects.leaf_regions, (a,b) -> a.properties.path.length > 2 and b.properties.path.length > 2 and a.properties.path[1] is b.properties.path[1] and a.properties.path[2] isnt b.properties.path[2]))
        .attr('d', path_generator)
        .attr('class', 'boundary low')
        .style('stroke-width', '0.9px')
        
    ### inset clipping of level one regions ###
    region_clips = land_layer.selectAll('.region_clip')
        .data(ontology.levels[1])
        
    region_clips.enter().append('clipPath')
        .attr
            class: 'region_clip'
            id: (n) -> "region_clip-#{n.name}"
      .append('path')
        .attr
            d: (n) -> path_generator(n.merged_region)
    
    land_layer.selectAll('.high_region')
        .data(ontology.levels[1])
      .enter().append('path')
        .attr
            class: 'high_region'
            d: (n) -> path_generator(n.merged_region)
            'clip-path': (n) -> "url(#region_clip-#{n.name})"
            
    ### draw the high-level boundaries ###
    land_layer.append('path')
        .datum(topojson.mesh(data, data.objects.leaf_regions, (a,b) -> a is b or a.properties.path[1] isnt b.properties.path[1]))
        .attr('d', path_generator)
        .attr('class', 'boundary high')
        .style('stroke-width', '1.1px')
        
    ### draw notable entities (cities) ###
    cities_data = [{
        "uri": "http://dbpedia.org/resource/Isaac_Newton",
        "i": 573,
        "j": -865
    },{
        "uri": "http://dbpedia.org/resource/Pablo_Picasso",
        "i": 1365,
        "j": -1237
    },{
        "uri": "http://dbpedia.org/resource/Rome",
        "i": 72,
        "j": -519
    },{
        "uri": "http://dbpedia.org/resource/New_York_City",
        "i": 353,
        "j": -453
    },{
        "uri": "http://dbpedia.org/resource/Earth",
        "i": -1225,
        "j": -1047
    },{
        "uri": "http://dbpedia.org/resource/Microsoft",
        "i": 264,
        "j": -1060
    },{
        "uri": "http://dbpedia.org/resource/Google",
        "i": 7,
        "j": -1110
    },{
        "uri": "http://dbpedia.org/resource/Apple_Inc.",
        "i": 106,
        "j": -1042
    },{
        "uri": "http://dbpedia.org/resource/Pink_Floyd",
        "i": -126,
        "j": -1518
    },{
        "uri": "http://dbpedia.org/resource/Yale_University",
        "i": 89,
        "j": -1227
    },{
        "uri": "http://dbpedia.org/resource/CNN",
        "i": 473,
        "j": -1203
    },{
        "uri": "http://dbpedia.org/resource/Dog",
        "i": -278,
        "j": -897
    },{
        "uri": "http://dbpedia.org/resource/Mosquito",
        "i": -419,
        "j": -880
    },{
        "uri": "http://dbpedia.org/resource/Bamboo",
        "i": -896,
        "j": -844
    },{
        "uri": "http://dbpedia.org/resource/Crow",
        "i": -856,
        "j": -1253
    },{
        "uri": "http://dbpedia.org/resource/Tulip",
        "i": -880,
        "j": -1062
    },{
        "uri": "http://dbpedia.org/resource/The_Matrix",
        "i": -900,
        "j": -503
    },{
        "uri": "http://dbpedia.org/resource/Yesterday",
        "i": -802,
        "j": -724
    },{
        "uri": "http://dbpedia.org/resource/The_Wall",
        "i": -331,
        "j": -519
    },{
        "uri": "http://dbpedia.org/resource/Scott_Pilgrim",
        "i": -728,
        "j": -646
    },{
        "uri": "http://dbpedia.org/resource/Images_and_Words",
        "i": -558,
        "j": -636
    },{
        "uri": "http://dbpedia.org/resource/Pizza",
        "i": -1227,
        "j": -873
    },{
        "uri": "http://dbpedia.org/resource/Christopher_Columbus",
        "i": -350,
        "j": -1461
    },{
        "uri": "http://dbpedia.org/resource/Cantonese",
        "i": -299,
        "j": -2043
    },{
        "uri": "http://dbpedia.org/resource/Euro",
        "i": -185,
        "j": -1989
    },{
        "uri": "http://dbpedia.org/resource/Jews",
        "i": -287,
        "j": -1944
    },{
        "uri": "http://dbpedia.org/resource/Oscar_Wilde",
        "i": 1226,
        "j": -1199
    },{
        "uri": "http://dbpedia.org/resource/IPhone",
        "i": -1291,
        "j": -901
    },{
        "uri": "http://dbpedia.org/resource/Adenosine_triphosphate",
        "i": -1182,
        "j": -1233
    },{
        "uri": "http://dbpedia.org/resource/Pneumonia",
        "i": -1012,
        "j": -1154
    },{
        "uri": "http://dbpedia.org/resource/Michael_Jordan",
        "i": 1043,
        "j": -802
    },{
        "uri": "http://dbpedia.org/resource/Elizabeth_II",
        "i": 1421,
        "j": -1282
    },{
        "uri": "http://dbpedia.org/resource/Julian_Assange",
        "i": -454,
        "j": -1585
    },{
        "uri": "http://dbpedia.org/resource/Alan_Turing",
        "i": 667,
        "j": -847
    },{
        "uri": "http://dbpedia.org/resource/Winston_Churchill",
        "i": 464,
        "j": -1042
    },{
        "uri": "http://dbpedia.org/resource/Stanley_Kubrick",
        "i": 464,
        "j": -1451
    },{
        "uri": "http://dbpedia.org/resource/Freddie_Mercury",
        "i": 1232,
        "j": -918
    }]
    cities = cities_layer.selectAll('.city')
        .data(cities_data)
        
    enter_cities = cities.enter().append('g')
        .on 'click', (c) ->
            ### trigger the selection of the city ###
            trigger map.node, 'select', {uri: c.uri}
        .attr
            class: 'city'
            transform: (c) ->
                [x, y] = _ij_to_xy(c.i, c.j)
                "translate(#{x},#{y})"
            
    enter_cities.append('text')
        .text((c) -> decodeURI(c.uri.replace('http://dbpedia.org/resource/','').replace(/_/g,' ')))
        .attr
            class: 'label halo'
            dx: 0.5
            dy: -0.5
            transform: 'rotate(60)'
            
    enter_cities.append('text')
        .text((c) -> decodeURI(c.uri.replace('http://dbpedia.org/resource/','').replace(/_/g,' ')))
        .attr
            class: 'label foreground'
            dx: 0.5
            dy: -0.5
            transform: 'rotate(60)'
            
    enter_cities.append('path')
        .attr
            class: 'hex_cell'
            d: _hex_path
            
    ### region labels ###
    region_labels = region_labels_layer.selectAll('.region_label')
        .data(ontology.levels[1].filter (n) -> n.merged_region.coordinates.length > 0) # some features could have been destroyed by simplification
        
    enter_region_labels = region_labels.enter().append('g')
        .attr
            class: 'region_label'
            transform: (n) ->
                [x,y] = path_generator.centroid(n.merged_region)
                return "translate(#{x},#{y})"
        
    enter_region_labels_halo = enter_region_labels.append('text')
        .attr
            class: 'halo label'
            transform: 'rotate(60)'
            y: (n) -> -(Math.floor(n.readable_label.length / 2) * 1.2 + 0.35) + 'em'
        
    enter_region_labels_halo.selectAll('tspan')
        .data((n) -> n.readable_label)
      .enter().append('tspan')
        .text((t) -> t)
        .attr
            x: 0
            dy: '1.2em'
        
    enter_region_labels_foreground = enter_region_labels.append('text')
        .attr
            class: 'label foreground'
            transform: 'rotate(60)'
            y: (n) -> -(Math.floor(n.readable_label.length / 2) * 1.2 + 0.35) + 'em'
            
    enter_region_labels_foreground.selectAll('tspan')
        .data((n) -> n.readable_label)
      .enter().append('tspan')
        .text((t) -> t)
        .attr
            x: 0
            dy: '1.2em'
    
    # default map mode is 'classes'
    map.mode 'classes'
    
    _update_lod(1)
    
map.update_selection = (selection) ->
    _preprocess_selection(selection)
    _move_cursor(selection.i, selection.j)
    
    ### clear all relations and draw them again ###
    relations_layer.selectAll('*').remove()
    
    relations = relations_layer.selectAll('.relation')
        .data(selection.relations)
        
    enter_relations = relations.enter().append('path')
        .attr
            class: 'relation_end hex_cell'
            d: _hex_path
            transform: (r) -> "translate(#{r.end.x},#{r.end.y})"
        .on 'click', (r) ->
            ### trigger the selection of the relation end ###
            trigger map.node, 'select', {uri: r.end.uri}
            
    enter_relations.append('title')
        .text((r) -> r.end.uri.replace('http://dbpedia.org/resource/','').replace(/_/g,' '))
        
_ij_to_xy = (i, j) ->
    return [j*(cos30*CELL_RADIUS*2)+(if i % 2 is 0 then 0 else cos30*CELL_RADIUS), i*3/2*CELL_RADIUS]
    
_move_cursor = (i, j) ->
    [x, y] = _ij_to_xy(i, j)
    cursor
        .attr
            transform: "translate(#{x}, #{y})"
        .style
            display: 'inline'
            
### find a hex given SVG coordinates ###
GRID_HEIGHT = sin30*CELL_RADIUS*3
GRID_WIDTH = cos30*CELL_RADIUS*2
C = sin30 * CELL_RADIUS
M = C / (GRID_WIDTH/2)

_get_hexagon = (point) ->
    x = point[0] + cos30*CELL_RADIUS
    y = point[1] + CELL_RADIUS
    
    row = Math.floor(y / GRID_HEIGHT)
    rowIsOdd = (row % 2 is 1)
    
    if rowIsOdd
        column = Math.floor((x - GRID_WIDTH/2) / GRID_WIDTH)
    else
        column = Math.floor(x / GRID_WIDTH)
        
    relY = y - (row * GRID_HEIGHT)
    
    if rowIsOdd
        relX = x - (column * GRID_WIDTH) - GRID_WIDTH/2
    else
        relX = x - (column * GRID_WIDTH)
    
    ### work out if the point is above either of the hexagon's top edges ###
    if relY < (-M * relX) + C # LEFT edge
        row -= 1
        if not rowIsOdd
            column -= 1
    
    else if relY < (M * relX) - C # RIGHT edge
        row -= 1
        if rowIsOdd
            column += 1
    
    return [row, column]
    
### precomputed hexagonal path ###
_hex_path = "M0,#{CELL_RADIUS} L#{cos30*CELL_RADIUS},#{sin30*CELL_RADIUS} L#{cos30*CELL_RADIUS},#{-sin30*CELL_RADIUS} L0,#{-CELL_RADIUS} L#{-cos30*CELL_RADIUS},#{-sin30*CELL_RADIUS} L#{-cos30*CELL_RADIUS},#{sin30*CELL_RADIUS} Z"


### Level Of Detail ###
REGION_LABEL_MIN_AREA = 80

_update_lod = (z) ->
    region_labels_layer.selectAll('.region_label')
        .classed 'hidden', (n) -> n.area * z*z < REGION_LABEL_MIN_AREA