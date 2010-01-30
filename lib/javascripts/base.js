/*
 * base.js
 * Amiel Martin
 * 2009-10-14
 */

// base.js provides some useful functions for global use under the namespace Base,
// as well as a namespace for variables to be registered from the server


var Base = (function(){
	var base = {};
	// register a variable for use within the Base namespace
	// there is an optional scope
	// You may want to use the +js_var+ helper found in javascript_helper.rb
	base.register_variable = function(key, value, scope) {
	    if (scope) {
	        if (typeof base[scope] === "undefined") base[scope] = {};
	        base[scope][key] = value;
	    } else {
	        base[key] = value;
	    }
	};
	base.reg = base.register_variable;


	// the following section provides an abstraction to the Firebug console
	//
	// you may want to do something like this: <% js_var :DEBUG, !Rails.env.production? %>
	if (base.DEBUG && window.console) {
		base.console = window.console;
	} else {
		var f = function(){};
		base.console = { log:f, debug:f, info:f, warn:f, error:f, assert:f, dir:f, dirxml:f, trace:f, group:f, groupEnd:f, time:f, timeEnd:f, profile:f, profileEnd:f, count:f };
	}
	
	// firebugx
	// if (!("console" in window) || !("firebug" in console)) {
	//     var names = ["log", "debug", "info", "warn", "error", "assert", "dir", "dirxml",
	//     "group", "groupEnd", "time", "timeEnd", "count", "trace", "profile", "profileEnd"];
	// 
	//     window.console = {};
	//     for (var i = 0; i < names.length; ++i)
	//         window.console[names[i]] = function() {}
	// }
	
	
	return base;
})();
