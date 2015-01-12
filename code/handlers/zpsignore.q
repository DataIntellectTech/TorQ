// This is used to allow .z.ps (async) calls to not be permission checked, logged etc.
// this can be useful as depending on how the connection is initiated, the username is not always available to check against
// It should be loaded last as it globally overrides .z.ps

\d .zpsignore

enabled:@[value;`enabled;1b]					// whether its enabled 
ignorelist:@[value;`ignorelist;(`upd;"upd";`.u.upd;".u.upd")]	// list of functions to ignore

if[enabled;
 .z.ps:{$[any first[y]~/:ignorelist;value y;x @ y]}[@[value;`.z.ps;{value}]]]
