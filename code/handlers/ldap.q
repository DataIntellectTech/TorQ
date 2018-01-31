// Functionality to aunthenticate user against LDAP server
// User attempts are cached
// This is used to allow .z.pw to be integrated with ldap

\d .ldap

enabled:@[value;`enabled;.z.o~`l64]                             / whether authentication is enabled
lib:`$getenv[`KDBLIB],"/",string[.z.o],"/torqldap";             / ldap library location
debug:@[value;`debug;0i]                                        / debug level for ldap library: 0i = none, 1i=normal, 2i=verbose
server:@[value;`server;"localhost"];                            / name of ldap server
port:@[value;`port;0i];                                         / port for ldap server
blocktime:@[value;`blocktime; 0D00:30:00];                      / time before blocked user can attempt authentication
checklimit:@[value;`checklimit;3];                              / number of attempts before user is temporarily blocked
checktime:@[value;`checktime;0D00:05];                          / period for user to reauthenticate without rechecking LDAP server
buildDNsuf:@[value;`buildDNsuf;""];                             / suffix used for building bind DN
buildDN:@[value;`buildDN;{{"uid=",string[x],",",buildDNsuf}}];  / function to build bind DN

out:{if[debug;:.lg.o[`ldap] x]};
err:{if[debug;:.lg.e[`ldap] x]};

init:{[lib]                                                     / initialise ldap library
  .ldap.authenticate:lib 2:(`authenticate;1);
 };

cache:([user:`$()]; pass:(); server:`$(); port:`int$(); time:`timestamp$(); attempts:`long$(); success:`boolean$(); blocked:`boolean$());  / create table to store login attempts

unblock:{[usr]
  if[-11h<>type usr; :.ldap.out"username must be passed as a symbol"];
  if[.ldap.cache[usr;`blocked];
    update attempts:0, success:0b, blocked:0b from `.ldap.cache where user=usr;
    :.ldap.out "unblocked user ",string usr;
  ];
 };

login:{[user;pass]                                              / validate login attempt
  incache:.ldap.cache user;                                     / get user from inputs
  dict:`version`server`port`bind_dn`pass!(.ldap.version;.ldap.server;.ldap.port;.ldap.buildDN user;pass);
  
  if[incache`blocked;
    if[null blocktime;                                          / if null blocktime then user is blocked
      .ldap.out"authentication attempts for user ",dict[`bind_dn]," are blocked";
      :0b];
    $[.z.p<bt:incache[`time]+.ldap.blocktime;                   / block user if blocktime has not elapsed
      [.ldap.out"authentication attempts for user ",dict[`bind_dn]," are blocked until ",string bt; :0b];
      update attempts:0, blocked:0b from `.ldap.cache where user=user];
  ];

  authorised:$[all (                                            / check if previously used details match
    incache[`success];                                          / previous attempt was a success
    incache[`time]>.z.p-.ldap.checktime;                        / previous attemp occured within checktime period
    incache[`pass]~np:md5 pass                                  / same password was used
  );
    1b;
    @[{.ldap.authenticate[x]`success};dict;0b]                  / attempt authentication
  ];
 
  `.ldap.cache upsert (user;np;`$.ldap.server;.ldap.port;.z.p; (1+0^incache`attempts;0) authorised;authorised;0b);  / upsert details of current attempt

  $[authorised;                                                 / display authentication status message
    .ldap.out"successfully authenticated user ",;
    .ldap.err"failed to authenticate user ",] dict`bind_dn;
 
  if[.ldap.checklimit<=.ldap.cache[user]`attempts;              / if attempt limit reached then block user
    .[`.ldap.cache;(user;`blocked);:;1b];
    .ldap.out"limit reached, user ",dict[`bind_dn]," has been locked out"];

  :authorised;
 };


if[enabled;
  libfile:hsym ` sv lib,`so;                                    / file containing ldap library
  if[()~key libfile;                                            / check ldap library file exists
    .lg.e[`ldap;"cannot find library file: ",1_string libfile]]; 
  init hsym .ldap.lib;                                          / initialise ldap library
  .z.pw:{all(.ldap.login;x).\:(y;z)}@[value;`.z.pw;{{[x;y]1b}}];  / redefine .z.pw
 ];

