_draw_leaf_labels = () ->
  leaf_labels = leaf_labels_layer.selectAll('.leaf_label')
    .data(ontology.leaves.filter (n) -> n.depth > 1 and n.leaf_region?)

  enter_leaf_labels = leaf_labels.enter().append('g')
    .attr
      class: 'leaf_label'
      transform: (n) -> "translate(#{n.x},#{n.y})"

  enter_text = enter_leaf_labels.append('text')
    .attr
      class: 'label'
      transform: 'rotate(60)'

  tspans = enter_text.selectAll('tspan')
      .data((n) -> n.readable_label)

  tspans.enter().append('tspan')
      .text((t) -> t)
      .attr
          x: 0
          dy: '1.2em'
          
