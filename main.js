main = d3.select(document);

var selection = null;

map.init('#map');
search_box.init('#search_box');
result_box.init('#result_box');
selection_box.init('#selection_box');

// load the ontology hierarchy and the TopoJSON map
queue()
    .defer(d3.json, 'ontology/ontology_canonical.json')
    .defer(d3.json, 'map/leaf_regions.topo.json')
    .await(function(error, ontology_data, topojson_data){
        if(error)
            throw error;
        
        ontology.init(ontology_data);
        map.load(topojson_data);
    });

function on_new_selection(json) {
    // extract integer coordinates from RDF
    try {
        json.i = parseInt(json.data_properties['http://wafi.iit.cnr.it/lod/ns/atlas#i'][0].value);
        json.j = parseInt(json.data_properties['http://wafi.iit.cnr.it/lod/ns/atlas#j'][0].value);
        
        selection = json;
    } catch(e) {
        console.error("Entity out of map: " + json.uri);
    }
    
    if (selection != null) {
        // preprocess selection
        var filtered_types = selection.types.filter(function(d) {return (d.value.indexOf("http://dbpedia.org/ontology/") == 0 && d.value.indexOf("http://dbpedia.org/ontology/Wikidata:") == -1);});
        selection.path = ontology.get_path(filtered_types);
        
        selection_box.update(selection);
        map.update_selection(selection);
    }
}

// UI callbacks
// ------------

// selection event
main.on('select', function() {
    if (d3.event.extra.hasOwnProperty("uri")) {
        d3.json("api/get_entity.php?uri=" + d3.event.extra.uri, function(error, json) {
            if (error) return console.warn(error);
            
            on_new_selection(json);
        });
    } else {
        d3.json("api/get_entity.php?i=" + d3.event.extra.i + "&j=" + d3.event.extra.j, function(error, json) {
            if (error) return console.warn(error);
            
            on_new_selection(json);
        });
    }
});

// search event
main.on('search', function() {
    if (d3.event.extra.string.length > 0) {
        d3.json("api/get_entities_from_string.php?string=" + d3.event.extra.string, function(error, json) {
            if (error) return console.warn(error);
            
            result_box.update(json);
        });
    }
});