// Returns the most specific class
function get_msc(node, classes) {
	if (classes.length > 1) 
		classes = classes.filter(function(c) {return c.value.replace("http://dbpedia.org/ontology/", "") != node.name;});
	else
		return classes;

	node.children.forEach(function(child) {
		classes = get_msc(child, classes);
	});

	return classes;
}