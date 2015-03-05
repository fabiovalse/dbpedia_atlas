main = d3.select(document);

var selection = null;

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