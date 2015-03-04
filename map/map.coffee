window.map = {}

SIZE = 100

map.init = (dom_node) ->
    map.svg = d3.select(dom_node)
    map.svg
        .attr
            viewBox: "#{-SIZE/2} #{-SIZE/2} #{SIZE} #{SIZE}"
            
    map.svg.append('rect')
        .attr
            x: -SIZE/2
            y: -SIZE/2
            width: SIZE
            height: SIZE
            stroke: 'red'
            
    bcr = map.svg.node().getBoundingClientRect()
    
    u_px_ratio = SIZE/Math.min(bcr.width, bcr.height)
    
    bluerect = map.svg.append('rect')
        .attr
            x: -bcr.width/2*u_px_ratio
            y: -bcr.height/2*u_px_ratio
            width: bcr.width*u_px_ratio
            height: bcr.height*u_px_ratio
            stroke: 'blue'
            
    d3.select(window).on 'resize', () ->
        bcr = map.svg.node().getBoundingClientRect()
        
        u_px_ratio = SIZE/Math.min(bcr.width, bcr.height)
        
        bluerect.attr
            x: -bcr.width/2*u_px_ratio
            y: -bcr.height/2*u_px_ratio
            width: bcr.width*u_px_ratio
            height: bcr.height*u_px_ratio
            stroke: 'green'