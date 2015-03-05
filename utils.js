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