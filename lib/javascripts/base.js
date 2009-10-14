/*
 * base.js
 * Amiel Martin
 * 2009-10-14
 *
 * 
 */

var Base = {};
// register a variable for use within the Base namespace
// there is an optional scope
// You may want to use the +js_var+ helper found in javascript_helper.rb
Base.register_variable = function(key, value, scope) {
    if (scope) {
        if (typeof Base[scope] === "undefined") Base[scope] = {};
        Base[scope][key] = value;
    } else {
        Base[key] = value;
    }
};
Base.reg = Base.register_variable;

// apply is used way to much here //

// log to the firebug console if window.console is available
Base.console = function(method) {
	if (Base.DEBUG && window.console && window.console[method])
		window.console[method].apply(null, Array.prototype.slice.apply(arguments, [1]));
};

// methods for logging
// this gives us Base.log, Base.console.log, Base.debug, etc
(function(methods){
	for (i in methods)
		(function(method_name){			
			Base[method_name] = Base.console[method_name] = function() {
				Base.console.apply(null, [ method_name, 'Base', "[" + (new Date).toLocaleTimeString() + "]" ].concat(Array.prototype.slice.apply(arguments)));
			};
		})(methods[i]);
})(['log', 'debug', 'info', 'warn', 'error']);

// all other firebug helpful methods
// this gives us Base.console.assert, Base.console.dir, etc
(function(methods){
	for (i in methods)
		(function(method_name){			
			Base.console[method_name] = function() {
				Base.console.apply(null, [ method_name ].concat(Array.prototype.slice.apply(arguments)));
			};
		})(methods[i]);
})(['assert', 'dir', 'dirxml', 'trace', 'group', 'groupEnd', 'time', 'timeEnd', 'profile', 'profileEnd', 'count']);
