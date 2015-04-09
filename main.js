main = d3.select(document);

var selection = null;
var last_request = null;
var initial_history_length = history.length;
var current_history_index = history.length;

map.init('#map');
search_box.init('#search_box');
result_box.init('#result_box');
selection_box.init('#selection_box');
details_box.init('#details_box');

// History handling
/*if (window.parent.location.hash != "") {

}*/

window.onpopstate = function (event) {
    if (event.state != null)
        on_new_selection(event.state);
    else {
        details_box.hide();
        selection_box.hide();
    }
};

var add_state = function(json) {
    history.pushState(json, "DBpedia Atlas: " + json.uri.split('/')[4], '#'+json.uri.split('/')[4]);
    document.title = "DBpedia Atlas: " + json.uri.split('/')[4];

    /*current_history_index += 1;*/
}

d3.select('#back').on('click', function() {
    history.back();

    /*if (current_history_index > initial_history_length+1) {
        current_history_index -= 1;
        history.back();
    }*/
});
d3.select('#forward').on('click', function() {
    history.forward();

    /*if (current_history_index < history.length) {
        current_history_index += 1;
        history.forward();
    }*/
});

function import_leaf_regions_statistics(d) {
    return {
        class: d.class,
        triple_count: +d.triple_count,
        obj_props_count: +d.obj_props_count,
        data_props_count: +d.data_props_count
    };
}

// load the ontology hierarchy and the TopoJSON map
queue()
    .defer(d3.json, 'data/ontology_canonical.json')
    .defer(d3.json, 'data/leaf_regions.topo.json')
    .defer(d3.json, 'data/untyped_region.topo.json')
    .defer(d3.csv, 'data/leaf_regions_statistics.csv', import_leaf_regions_statistics)
    .await(function(error, ontology_data, leaf_regions_data, untyped_region_data, stats_data){
        if(error)
            throw error;
        
        ontology.init(ontology_data);
        map.load(leaf_regions_data, untyped_region_data, stats_data);
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
        var filtered_types = selection.types.filter(function(d) {return ((d.value.indexOf("http://dbpedia.org/ontology/") == 0 && d.value.indexOf("http://dbpedia.org/ontology/Wikidata:") == -1) || d.value == "http://www.w3.org/2002/07/owl#Thing" || d.value == "http://www.opengis.net/gml/_Feature");});
        selection.path = ontology.get_path(filtered_types);
        
        selection_box.update(selection);
        details_box.update(selection);
        map.update_selection(selection);
        
        selection_box.show();
        details_box.show();
    }
}

// UI callbacks
// ------------

// selection event
main.on('select', function() {
    last_request = new Date().getTime()

    d3.select('body').style('cursor', 'progress');

    if (d3.event.extra.hasOwnProperty("uri")) {
        d3.json("api/get_entity.php?uri=" + d3.event.extra.uri + "&ts=" + last_request, function(error, json) {
            if (error) return console.warn(error);

            add_state(json);
            
            if (last_request == json["ts"])
                on_new_selection(json);

            d3.select('body').style('cursor', 'auto');
        });
    } else {
        d3.json("api/get_entity.php?i=" + d3.event.extra.i + "&j=" + d3.event.extra.j + "&ts=" + last_request, function(error, json) {
            if (error) return console.warn(error);

            add_state(json);

            if (last_request == json["ts"])
                on_new_selection(json);

            d3.select('body').style('cursor', 'auto');
        });
    }
});

// search event
main.on('search', function() {
    if (d3.event.extra.string.length > 0) {
        d3.json("api/lookup.php?text=" + d3.event.extra.string, function(error, json) {
            if (error) {
                alert("The DBpedia lookup service is down");
                return console.warn(error);
            };
            
            result_box.update(json);
        });
    }
    else {
        // empty the results
        result_box.update([]);
    }
});

// blur & focus events for results box
map.node.on('click', function() {
    result_box.hide();
});
selection_box.node.on('click', function() {
    result_box.hide();
});
details_box.node.on('click', function() {
    result_box.hide();
});
search_box.node.select('#search_textbox').on('click', function() {
    result_box.show();
});