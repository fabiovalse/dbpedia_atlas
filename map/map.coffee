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
relations_layer = null

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
        .scaleExtent([0.01, 49])
        .on 'zoom', () ->
            zoom_layer.attr
                transform: "translate(#{d3.event.translate})scale(#{d3.event.scale})"
                
    vis = zoom_layer.append('g')
        .attr
            transform: 'translate(26,0)'
        
    map_layer = vis.append('g')
    sea_layer = map_layer.append('g')
    land_layer = map_layer.append('g')
    
    ### cursor ###
    cursor = vis.append('path')
        .attr
            class: 'cursor'
            d: (r) -> "M0,#{CELL_RADIUS} L#{cos30*CELL_RADIUS},#{sin30*CELL_RADIUS} L#{cos30*CELL_RADIUS},#{-sin30*CELL_RADIUS} L0,#{-CELL_RADIUS} L#{-cos30*CELL_RADIUS},#{-sin30*CELL_RADIUS} L#{-cos30*CELL_RADIUS},#{sin30*CELL_RADIUS} Z"
    
    land_layer.on 'click', () ->
        # disable cursor movement when panning
        # see https://github.com/mbostock/d3/wiki/Drag-Behavior
        return if d3.event.defaultPrevented
        
        ### move the cursor to provide feedback ###
        h = _get_hexagon(d3.mouse(this))
        _move_cursor(h[0], h[1])
        
        ### trigger a selection event ###
        trigger map.node, 'select', {i: h[0], j: h[1]}
        
        
    ### relations ###
    relations_layer = vis.append('g')
    
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
    
### colors ###
class_color = {'Person': 'rgba(228, 110, 121, 1)', 'Organisation': 'rgba(182, 142, 71, 1)', 'Place': 'rgba(101, 166, 94, 1)', 'Work': 'rgba(185, 121, 201, 1)', 'Species': 'rgba(84, 170, 173, 1)', 'Event': 'rgba(80, 155, 233, 1)', 'Other': 'rgba(148, 149, 145, 1)'}
    
map.load = (data) ->
    ### presimplify the topology (compute the effective area (z) of each point) ###
    console.debug('Map - Presimplifying...')
    topojson.presimplify(data)
    console.debug('Map - ...done.')
    
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
            transform: 'scale(0.05)'
    
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
    
    ### draw all the leaf regions ###
    land_layer.selectAll('.region')
        .data(topojson.feature(data, data.objects.leaf_regions).features)
      .enter().append('path')
        .attr
            class: 'region'
            d: path_generator
            fill: (d) ->
                if d.properties['path'].length > 2 and d.properties['path'][2] of class_color
                    return class_color[d.properties['path'][2]]
                else if d.properties['path'].length > 1 and d.properties['path'][1] of class_color
                    return class_color[d.properties['path'][1]]
                else
                    return class_color['Other']
                    
    ### actual land boundary ###
    # land_layer.append('use')
        # .attr('class', 'boundary high land-fill')
        # .attr('xlink:href', '#land')
        
    ### draw the leaf regions boundaries ###
    land_layer.append('path')
        .datum(topojson.mesh(data, data.objects.leaf_regions, (a,b) -> a isnt b and a.properties.path[1] is b.properties.path[1]))
        .attr('d', path_generator)
        .attr('class', 'boundary low')
        .style('stroke-width', '0.1px')
        
    land_layer.append('path')
        .datum(topojson.mesh(data, data.objects.leaf_regions, (a,b) -> a is b or a.properties.path[1] isnt b.properties.path[1]))
        .attr('d', path_generator)
        .attr('class', 'boundary high')
        .style('stroke-width', '1.1px')
        
map.update_selection = (selection) ->
    _move_cursor(selection.i, selection.j)
    
    ### show relational links ###
    relations_data = []
    
    ### outgoing links ###
    selection.object_properties.outgoing.forEach (t) ->
        if 'i' of t and 'j' of t
            relations_data.push {'s': selection, 'p': t.p.value, 'o': {uri: t.o.value, i: t.i.value, j: t.j.value}}
        else
            console.error('Link to out-of-map entity: ' + t.o.value)
        
    ### incoming links ###
    selection.object_properties.incoming.forEach (t) ->
        if 'i' of t and 'j' of t
            relations_data.push {'s': {uri: t.s.value, i: t.i.value, j: t.j.value}, 'p': t.p.value, 'o': selection}
        else
            console.error('Link from out-of-map entity: ' + t.s.value)
        
    ### FIXME links to self are currently ignored ###
    
    relations = relations_layer.selectAll('.relation')
        .data(relations_data, (r) -> "#{r.s.uri}>>>#{r.p}>>>#{r.o.uri}")
      
    relations.enter().append('path')
        .attr
            class: 'relation'
            d: (r) ->
                [sx, sy] = _ij_to_xy(r.s.i, r.s.j)
                [ox, oy] = _ij_to_xy(r.o.i, r.o.j)
                return "M#{sx} #{sy} C#{sx} #{sy-12} #{ox} #{oy-12} #{ox} #{oy}"
                
    relations.exit()
        .remove()
        
_ij_to_xy = (i, j) ->
    return [j*(cos30*CELL_RADIUS*2)+(if i % 2 is 0 then 0 else cos30*CELL_RADIUS), i*3/2*CELL_RADIUS]
    
_move_cursor = (i, j) ->
    [x, y] = _ij_to_xy(i, j)
    cursor
        .attr
            transform: "translate(#{x}, #{y})"
            
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
    