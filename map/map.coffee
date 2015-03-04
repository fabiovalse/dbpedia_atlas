window.map = {}

### globals ###
svg = null
defs = null
zoom_layer = null
vis = null
map_layer = null

SIZE = 100

map.init = (dom_node) ->
    svg = d3.select(dom_node)
    svg
        .attr
            viewBox: "#{-SIZE/2} #{-SIZE/2} #{SIZE} #{SIZE}"
            
    defs = svg.append('defs')
    
    ### init test ###
    svg.append('rect')
        .attr
            x: -SIZE/2
            y: -SIZE/2
            width: SIZE
            height: SIZE
            stroke: 'red'
            
    bcr = svg.node().getBoundingClientRect()
    
    u_px_ratio = SIZE/Math.min(bcr.width, bcr.height)
    
    bluerect = svg.append('rect')
        .attr
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
            transform: 'translate(26,-25) rotate(-60)'
        
    map_layer = vis.insert('g', ':last-child')
    
### custom projection to make hexagons appear regular (y axis is also flipped) ###
RADIUS = 0.02
dx = RADIUS * 2 * Math.sin(Math.PI / 3)
dy = RADIUS * 1.5

SIMPLIFICATION = 100

path_generator = d3.geo.path()
    .projection d3.geo.transform({
        point: (x,y,z) ->
            ### Level of Detail ###
            if z >= SIMPLIFICATION
                this.stream.point(x * dx / 2, -(y - (2 - (y & 1)) / 3) * dy / 2)
    })
    
### colors ###
class_color = {'Person': '#E14E5F', 'Organisation': '#A87621', 'Place': '#43943E', 'Work': '#AC5CC4', 'Species': '#2E99A0', 'Event': '#2986EC', 'Other': '#7E7F7E'}
    
map.load = (data) ->
    ### presimplify the topology (compute the effective area (z) of each point) ###
    console.debug('Map - Presimplifying...')
    topojson.presimplify(data)
    console.debug('Map - ...done.')
    
    ### define the level zero region (the land) ###
    defs.append('path')
        .datum(topojson.mesh(data, data.objects.leaf_regions, (a,b) -> a is b))
        .attr('id', 'land')
        .attr('d', path_generator)

    ### faux land glow (using filters takes too much resources) ###
    map_layer.append('use')
        .attr('class', 'land-glow-outer')
        .attr('xlink:href', '#land')

    map_layer.append('use')
        .attr('class', 'land-glow-inner')
        .attr('xlink:href', '#land')

    ### actual land ###
    #map_layer.append('use')
    #    .attr('class', 'land-fill')
    #    .attr('xlink:href', '#land')
    
    ### draw all the leaf regions ###
    map_layer.selectAll('.region')
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
                    
    ### draw the leaf regions boundaries ###
    map_layer.append('path')
        .datum(topojson.mesh(data, data.objects.leaf_regions, (a,b) -> a isnt b))
        .attr('d', path_generator)
        .attr('class', 'boundary')
        .style('stroke-width', '0.2px')
        
    map_layer.append('path')
        .datum(topojson.mesh(data, data.objects.leaf_regions, (a,b) -> a.properties.path[1] isnt b.properties.path[1]))
        .attr('d', path_generator)
        .attr('class', 'boundary')
        .style('stroke-width', '1px')