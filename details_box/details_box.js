(function() {
window.details_box = {};

var box;
var data_box;

details_box.init = function(dom_selector) {
    box = d3.select(dom_selector);

    details_box.node = box;
    
    data_box = box.append('table');
    box.append('div')
        .attr('class', 'header')
        .text('Outgoing relations');
    outgoing_box = box.append('table');
    box.append('div')
        .attr('class', 'header')
        .text('Incoming relations');
    incoming_box = box.append('table');
    
    details_box.hide();
}

details_box.update = function(selection) {
    box.property('scrollTop', 0);
    
    /*  Data properties
    */
    data_properties = Object.keys(selection.data_properties).map(function(k){ return {p: k, objs: selection.data_properties[k]}; });
    
    if(data_properties.length > 0) {
        redraw_table(data_properties.sort(sort_data_prop), data_box, 'data');
    }
    else {
        data_box.html('<div class="no_data">No data properties.</div>');
    }
    
    /*  Object properties OUTGOING
    */
    var outgoing_data = [];
    var current_p = null;

    selection.object_properties.outgoing.sort(sort_obj_prop).forEach(function(d) {
        // group by predicate
        if (current_p != d.p.value) {
            outgoing_data.push({p: d.p.value, objs: [d.o]});
            current_p = d.p.value;
        }
        else {
            // data is already sorted by predicate, value can be added to last group
            outgoing_data[outgoing_data.length-1].objs.push(d.o);
        }
    });
    
    if(outgoing_data.length > 0) {
        redraw_table(outgoing_data, outgoing_box, 'outgoing');
    }
    else {
        outgoing_box.html('<div class="no_data">No outgoing relations.</div>');
    }
    
    /*  Object properties INCOMING
    */
    var incoming_data = [];
    var current_p = null;

    selection.object_properties.incoming.sort(sort_obj_prop).forEach(function(d) {
        // group by predicate
        if (current_p != d.p.value) {
            incoming_data.push({p: d.p.value, objs: [d.s]});
            current_p = d.p.value;
        }
        else {
            // data is already sorted by predicate, value can be added to last group
            incoming_data[incoming_data.length-1].objs.push(d.s);
        }
    });
    
    if(incoming_data.length > 0) {
        redraw_table(incoming_data, incoming_box, 'incoming');
    }
    else {
        incoming_box.html('<div class="no_data">No incoming relations.</div>');
    }
}

function redraw_table(data, table, property_type) {
    table.selectAll('*').remove();
    var current_img = null;

    var groups = table.selectAll('tbody')
        .data(data);
        
    groups.enter().append('tbody');
    
    var rows = groups.selectAll('tr')
        .data(function(d) { return d.objs; });
    
    rows.enter().append('tr')
        .html(function(d, i){
            var prop = d3.select(this.parentNode).datum();
            var predicate_cell = '<td class="predicate'+(i === 0 ? '' : ' omitted')+'" title="'+prop.p+'">'+(property_type === 'outgoing' ? '<span class="dir">has </span>' : '')+(property_type === 'incoming' ? '<span class="dir">is </span>' : '')+format_uri(prop.p)+(property_type === 'incoming' ? '<span class="dir"> of</span>' : '')+'</td>';
            
            var value_cell;
            if (property_type === 'data' && prop.p == 'http://dbpedia.org/ontology/thumbnail' && (d.value.search(/.jpg/i) != -1 || d.value.search(/.png/i) != -1 || d.value.search(/.svg/i) != -1 || d.value.search(/.gif/i) != -1)) {
                value_cell = '<td><a href="'+current_img+'" target="_blank"><img src="'+d.value+'"></a></td>';
            }
            else if (property_type === 'data') {
                if (prop.p == 'http://xmlns.com/foaf/0.1/depiction')
                    current_img = d.value;

                value_cell = d.type === 'uri' ? '<td><a href="'+d.value+'" target="_blank">'+d.value+'</a></td>' : '<td>'+d.value+'</td>';
            }
            else {
                value_cell = '<td class="object_uri">'+format_uri(d.value)+'</td>';
            }
            
            return predicate_cell + value_cell;
        });
        
    // clickable object URIs
    if(property_type === 'outgoing' || property_type === 'incoming') {
        table.selectAll('.object_uri')
            .on('click', function() {
                var d = d3.select(this.parentNode).datum();
                trigger(details_box.node, 'select', {uri: d.value});
            });
    }
}

var sort_data_prop = function (a, b) {
    if (format_uri(a.p) > format_uri(b.p))
        return 1;
    if (format_uri(a.p) < format_uri(b.p))
        return -1;
    return 0;
}

var sort_obj_prop = function (a, b) {
    if (format_uri(a.p.value) > format_uri(b.p.value))
        return 1;
    if (format_uri(a.p.value) < format_uri(b.p.value))
        return -1;
    return 0;
}

details_box.hide = function() {
    details_box.node.style('display', 'none');
}
details_box.show = function() {
    details_box.node.style('display', 'inline');
}

}).call(this);