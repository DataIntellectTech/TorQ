// This script does publish and subscribe
// For the time being, we are just going to rely on u.[q|k]
// if this isn't available, then the publish and subscribe methods are empty

\d .ps

loaded:1b
// check if u.[q|k] is loaded
u:all `pub`sub`init in key `.u

publish:$[u;.u.pub;{[tab;data]}]
subscribe:$[u;.u.sub;{[tab;syms]}]
init:$[u;.u.init;{[]}]
initialise:{.ps.init[]; .ps.initialised:1b}
