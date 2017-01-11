// Functionality to aunthenticate user against LDAP server
// User attempts are cached

\d .ldap

enabled:@[value;`enabled;.z.o~`l64]      		    // whether authentication is enabled
lib:`$getenv[`KDBLIB],"/",string[.z.o],"/kxldap";   // ldap library location
debug:@[value;`debug;0i]					        // debug level for ldap library: 0i = none, 1i=normal, 2i=verbose
server:@[value;`server;"localhost"];                // name of ldap server
port:@[value;`port;0i];                             // port for ldap server
blocktime:@[value;`blocktime; 0D00:30:00];          // time before blocked user can attempt authentication
checklimit:@[value;`checklimit;3];                  // number of attempts before user is temporarily blocked
checktime:@[value;`checktime;0D00:05];              // period for user to reauthenticate without rechecking LDAP server

authenticate:{[x]};

init:{[lib]
  0N!("loading lib";lib);
  .ldap.print_auth_usage:lib 2:(`print_auth_usage;1);
  .ldap.authenticate:lib 2:(`authenticate;1);
 };

       
if[enabled;
  libfile:hsym ` sv lib,`so;                                    / file containing ldap library
  libexists:not ()~key libfile;                                 / check ldap library file exists
  if[not .ldap.libexists; :.lg.e[`ldap;"no such file ",1_string libfile]]; 
  init hsym .ldap.lib;                                          / initialise if library is found
 ];


/-create table to store login attempts
cache:([user:`$()]; pass:(); server:`$(); port:`int$(); time:`timestamp$(); attempts:`long$(); success:`boolean$(); blocked:`boolean$());

buildDN:{[x]
  :"uid=",string[x],",ou=users,dc=aquaq,dc=co,dc=uk";
 };

login:{[user;pass]                                              / validate login attempt

  incache:.ldap.cache user;                                     / get user from inputs
  
  if[incache`blocked;
    if[.z.p<bt:incache[`time]+.ldap.blocktime;
      .lg.e[`ldap] "authentication attempts blocked until ",string bt;
      :0b];
    update attempts:0, blocked:0b from `.ldap.cache where user=user;
  ];

  dict:`version`server`port`bind_dn`pass!(.ldap.version;.ldap.server;.ldap.port;.ldap.buildDN user;pass);

  authorised:$[all (                                            / check if previously used details match
    incache[`success];                                          / previous attempt was a success
    incache[`time]>.z.p-.ldap.checktime;                        / previous attemp occured within checktime period
    incache[`pass]~np:md5 pass                                  / same password was used
  );
    1b;
    @[{.ldap.authenticate[x]`success};dict;0b]                  / attempt authentication
  ];
 
 
  `.ldap.cache upsert (user;np;`$.ldap.server; .ldap.port; .z.p; (1+0^incache`attempts;0) authorised;authorised;0b);  / upsert details of current attempt

  $[authorised;                                                 / display authentication status message
    .lg.o[`ldap] "Successfully authenticated";
    .lg.e[`ldap] "Authentication failed"];
  
  if[.ldap.checklimit<=.ldap.cache[user]`attempts;              / if attempt limit reached then block users
    .[`.ldap.cache;(user;`blocked);:;1b];
    .lg.e[`ldap] "Limit reached, you have been locked out"];

  :authorised;
 };
