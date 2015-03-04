map.init('#map');
search_box.init('#search_box');
result_box.init('#result_box');
selection_box.init('#selection_box');

// load the TopoJSON map
d3.json('map/leaf_regions.topo.json', function(topojson_data){
    map.load(topojson_data);
});