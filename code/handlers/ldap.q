// Functionality to aunthenticate user against LDAP server
// User attempts are cached
// This is used to allow .z.pw to be integrated with ldap

\d .ldap

enabled:    @[value;`enabled;.z.o~`l64]                            / whether authentication is enabled
lib:        `$getenv[`KDBLIB],"/",string[.z.o],"/kdbldap";         / ldap library location
debug:      @[value;`debug;0i]                                     / debug level for ldap library: 0i = none, 1i=normal, 2i=verbose
servers:    @[value;`servers; enlist `$"ldap://localhost:0"];      / symbol-list of <schema>://<host>:<port> 
blocktime:  @[value;`blocktime; 0D00:30:00];                       / time before blocked user can attempt authentication
checklimit: @[value;`checklimit;3];                                / number of attempts before user is temporarily blocked
checktime:  @[value;`checktime;0D00:05];                           / period for user to reauthenticate without rechecking LDAP server
buildDNsuf: @[value;`buildDNsuf;""];                               / suffix used for building bind DN
buildDN:    @[value;`buildDN;{{"uid=",string[x],",",buildDNsuf}}]; / function to build bind DN
version:    @[value;`version;3];                                   / ldap version number 

out:{if[debug;:.lg.o[`ldap] x]};
err:{if[debug;:.lg.e[`ldap] x]};

initialise:{[lib]                                                     / initialise ldap library
  .ldap.init:lib 2:(`kdbldap_init;2);
  .ldap.setOption:lib 2:(`kdbldap_set_option;3);
  .ldap.bind_s:lib 2:(`kdbldap_bind_s;4);
  .ldap.err2string:lib 2:(`kdbldap_err2string;1);
  .ldap.startTLS:lib 2:(`kdbldap_start_tls;1);
  .ldap.setGlobalOption:lib 2:(`kdbldap_set_global_option;2);
  .ldap.getOption:lib 2:(`kdbldap_get_option;2);
  .ldap.getGlobalOption:lib 2:(`kdbldap_get_global_option;1);
  .ldap.interactive_bind_s:lib 2:(`kdbldap_interactive_bind_s;5);
  .ldap.search_s:lib 2:(`kdbldap_search_s;8);
  .ldap.unbind_s:lib 2:(`kdbldap_unbind_s;1);
  r:.ldap.init[.ldap.sessionID; .ldap.servers];
  if[0<>r;.ldap.err "Error initialising LDAP: ",.ldap.err2string[r]];
  s:.ldap.setOption[.ldap.sessionID;`LDAP_OPT_PROTOCOL_VERSION;.ldap.version];
  if[0<>s;.ldap.err "Error setting LDAP option: ",.ldap.err2string[s]];
 };

sessionID:0i

cache:([user:`$()]; pass:(); server:`$(); port:`int$(); time:`timestamp$(); attempts:`long$(); success:`boolean$(); blocked:`boolean$());  / create table to store login attempts

unblock:{[usr]
  if[-11h<>type usr; :.ldap.out"username must be passed as a symbol"];
  if[.ldap.cache[usr;`blocked];
    update attempts:0, success:0b, blocked:0b from `.ldap.cache where user=usr;
    :.ldap.out "unblocked user ",string usr;
  ];
 };

bind:{[sess;customDict]
  defaultKeys:`dn`cred`mech;
  defaultVals:```;
  defaultDict:defaultKeys!defaultVals;
  if[customDict~(::);customDict:()!()];
  if[99h<>type customDict;'"customDict must be (::) or a dictionary"];
  updDict:defaultDict,customDict;
  bindSession:.ldap.bind_s[sess;;;]. updDict defaultKeys;
  bindSession
  }

login:{[user;pass]                                              / validate login attempt
  incache:.ldap.cache user;                                     / get user from inputs
  dict:`dn`cred!(.ldap.buildDN user;pass);
  
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
    enlist[`ReturnCode]!enlist 0i;
    .[.ldap.bind;(.ldap.sessionID;dict);enlist[`ReturnCode]!enlist -2i]                 / attempt authentication
  ];
 
  `.ldap.cache upsert (user;np;`$.ldap.server;.ldap.port;.z.p; $[0=authorised[`ReturnCode];0;1+0^incache`attempts] ;authorised[`ReturnCode]~0i;0b);  / upsert details of current attempt

  $[authorised[`ReturnCode]~0i;                                                 / display authentication status message
    .ldap.out"successfully authenticated user ",;
    .ldap.err"failed to authenticate user ",.ldap.err2string[authorised[`ReturnCode]],] dict[`dn];
 
  if[.ldap.checklimit<=.ldap.cache[user]`attempts;              / if attempt limit reached then block user
    .[`.ldap.cache;(user;`blocked);:;1b];
    .ldap.out"limit reached, user ",dict[`dn]," has been locked out"];

  :authorised[`ReturnCode]~0i;
 };


if[enabled;
  libfile:hsym ` sv lib,`so;                                    / file containing ldap library
  if[()~key libfile;                                            / check ldap library file exists
    .lg.e[`ldap;"cannot find library file: ",1_string libfile]]; 
  initialise hsym .ldap.lib;                                          / initialise ldap library
  .dotz.set[`.z.pw;{all(.ldap.login;x).\:(y;z)}@[value;.dotz.getcommand[`.z.pw];{{[x;y]1b}}]];  / redefine .z.pw
 ];

