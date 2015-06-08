(function() {
window.selection_box = {};

var box;
var header;
var linkedmdb_link;
var freebase_link;
var path;

selection_box.init = function(dom_selector) {
    box = d3.select(dom_selector);

    selection_box.node = box;
    
    freebase_link = box.append('a')
        .attr('target', '_blank');
        
    freebase_link
        .append('img')
            .attr('class', 'external_link')
            .attr('src', 'img/freebase_logo.png')
            .attr();
            
    linkedmdb_link = box.append('a')
        .attr('target', '_blank');
        
    linkedmdb_link
        .append('img')
            .attr('class', 'external_link')
            .attr('src', 'img/linkedmdb_logo.png');
            
    header = box.append('header');
    
    path = box.append('div')
        .attr('class', 'path');
        
    
    selection_box.hide();
}

selection_box.update = function(selection) {
    /*  Sets the title, links (LinkedMDB, Freebase) and the most specific type
    */
    if ('http://www.w3.org/2000/01/rdf-schema#label' in selection['data_properties'])
        header.text(selection['data_properties']['http://www.w3.org/2000/01/rdf-schema#label'][0].value);
    else
        header.text(selection.uri.split("/").slice(-2)[0].replace(/_/g, ' ') + " #" + selection.uri.split("/").slice(-2)[1]);
    
    linkedmdb_link
        .attr('href', selection.uri)
        .attr('title', 'Open "'+format_uri(selection.uri)+'" in LinkedMDB.');
        

    if ('http://xmlns.com/foaf/0.1/page' in selection.data_properties) {
        freebase_link.classed('hidden', false);
        freebase_link
            .attr('href', selection.data_properties['http://xmlns.com/foaf/0.1/page'][0].value)
            .attr('title', 'Open "'+format_uri(selection.uri)+'" in Freebase.');
    } else {
        freebase_link.classed('hidden', true);
    }

    path.selectAll('.class').remove();
    
    classes = path.selectAll('.class')
        .data(selection.types);
        
    classes.enter().append('span')
        .attr('class', 'class msc')
        .html(function(d) {
            return (d.value.indexOf("/movie/") > -1) ? d.value.replace("http://data.linkedmdb.org/resource/movie/", "").replace(/_/g, " ") : d.value.replace("http://data.linkedmdb.org/resource/oddlinker/", "").replace(/_/g, " ");
        });
}

selection_box.hide = function() {
    selection_box.node.style('display', 'none');
}
selection_box.show = function() {
    selection_box.node.style('display', 'inline');
}

}).call(this);
