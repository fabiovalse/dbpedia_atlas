function trigger(target, name, extra) {
    // try to convert from d3 to plain node
    try {
        target = target.node();
    }
    catch(_){}
    
    var e = document.createEvent('Events');
    e.initEvent(name, true, true);
    e.extra = extra;
    target.dispatchEvent(e);
}

var format_uri = function(key) {
	var newKey = "";
	var flag = false;

	key = decodeURIComponent(key).replace(/_/g, " ");
	uriKey = key;

	splittedKey = key.split("/");
	key = splittedKey[splittedKey.length-1];

	if (key.indexOf("#") != -1) {
		key = key.substring(key.indexOf("#")+1);
	}

	for (i in key) {
		if (!flag && key.charAt(i) === key.charAt(i).toUpperCase() && key.charAt(i) !== key.charAt(i).toLowerCase() && i != 0) {
			newKey += " ";
			newKey += key.charAt(i);
			flag = true;
		} else {
			newKey += key.charAt(i);
			flag = false;
		}
	}

	return (newKey.charAt(0).toUpperCase() + newKey.slice(1));
}