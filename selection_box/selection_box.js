(function() {
window.selection_box = {};

var box;
var header;
var dbpedia_link;
var wikipedia_link;
var path;
var hex_tooltip;

selection_box.init = function(dom_selector) {
    box = d3.select(dom_selector);

    selection_box.node = box;
    
    var RADIUS = 14;
    var sin30 = Math.sin(Math.PI/6);
    var cos30 = Math.cos(Math.PI/6);
    var hex_svg = box.append('svg')
        .attr('width', '32px')
        .attr('height', '32px')
        .attr('viewBox', '-16 -16 32 32');
        
    var hex = hex_svg.append('path')
        .attr('class', 'hex')
        .attr('d', 'M0,'+RADIUS+' L'+(cos30*RADIUS)+','+(sin30*RADIUS)+' L'+(cos30*RADIUS)+','+(-sin30*RADIUS)+' L0,'+(-RADIUS)+' L'+(-cos30*RADIUS)+','+(-sin30*RADIUS)+' L'+(-cos30*RADIUS)+','+(sin30*RADIUS)+' Z');
        
    hex_tooltip = hex.append('title')
        .text('Instance');
        
    wikipedia_link = box.append('a')
        .attr('target', '_blank');
        
    wikipedia_link
        .append('img')
            .attr('class', 'external_link')
            .attr('src', 'img/wikipedia_logo.png')
            .attr();
            
    dbpedia_link = box.append('a')
        .attr('target', '_blank');
        
    dbpedia_link
        .append('img')
            .attr('class', 'external_link')
            .attr('src', 'img/dbpedia_logo.png');
            
    header = box.append('header');
    
    path = box.append('div')
        .attr('class', 'path');
        
    
    selection_box.hide();
}

selection_box.update = function(selection) {
    /*  Sets the title, links (DBpedia, Wikipedia) and the most specific type
    */
    header.text(decodeURI(selection.uri.replace("http://dbpedia.org/resource/", "").replace(/_/g, " ")) + " ");
    
    dbpedia_link
        .attr('href', selection.uri)
        .attr('title', 'Open "'+format_uri(selection.uri)+'" in DBpedia.');
        
    wikipedia_link
        .attr('href', function() {
            splitted = selection.uri.split('/');
            return 'http://en.wikipedia.org/wiki/' + splitted[splitted.length-1];
        })
        .attr('title', 'Open "'+format_uri(selection.uri)+'" in Wikipedia.');

    path.selectAll('.class').remove();
    
    classes = path.selectAll('.class')
        .data(selection.path);
        
    classes.enter().append('span')
        .attr('class', function(d, i) {return (i < selection.path.length-1) ? 'class' : 'class msc'})
        //.attr('title', function(d) {return d;}) FIXME provide original URIs
        .html(function(d, i) {
            var formatted_uri = format_uri(d).replace('Owl:','');
            return (i < selection.path.length-1) ? formatted_uri + " > " : formatted_uri;
        });
}

selection_box.hide = function() {
    selection_box.node.style('display', 'none');
}
selection_box.show = function() {
    selection_box.node.style('display', 'inline');
}

}).call(this);
