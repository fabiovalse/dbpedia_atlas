main = d3.select(document);

map.init('#map');
search_box.init('#search_box');
result_box.init('#result_box');
selection_box.init('#selection_box');

// load the TopoJSON map
d3.json('map/leaf_regions.topo.json', function(data){
    preprocess_topojson(data);
    map.load(data);
});

function preprocess_topojson(data) {
    topojson.feature(data, data.objects.leaf_regions).features.forEach(function(f){
        // parse the path into an array
        f.properties.path = JSON.parse(f.properties.path);
    });
}

// UI callbacks
// ------------

// selection event
main.on('select', function() {
    if (d3.event.extra.hasOwnProperty("uri")) {

    } else {
        d3.json("api/get_entity.php?i=" + d3.event.extra.i + "&j=" + d3.event.extra.j, function(error, json) {
            if (error) return console.warn(error);
            
            // extract integer coordinates from RDF
            json.i = int(json.data_properties['http://wafi.iit.cnr.it/lod/dbpedia/atlas#i'].value);
            json.j = int(json.data_properties['http://wafi.iit.cnr.it/lod/dbpedia/atlas#j'].value);
            
            selection_box.update(json);
            map.update_selection(json);
        });
    }
});