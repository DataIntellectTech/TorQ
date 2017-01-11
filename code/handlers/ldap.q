// This is used to allow .z.pw to be integrated with ldap

\d .ldap

enabled:@[value;`enabled;.z.o~`l64];      		    // whether authentication is enabled

if[enabled;.z.pw:.ldap.login];
