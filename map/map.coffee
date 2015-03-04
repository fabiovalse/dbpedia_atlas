window.map = {}

### globals ###
svg = null

SIZE = 100

map.init = (dom_node) ->
    svg = d3.select(dom_node)
    svg
        .attr
            viewBox: "#{-SIZE/2} #{-SIZE/2} #{SIZE} #{SIZE}"
            
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
            
map.load = (topojson_data) ->
    console.log topojson_data
    