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