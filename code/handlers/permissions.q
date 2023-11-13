
\d .pm

if[@[1b; `.access.enabled;0b]; ('"controlaccess.q already active";exit 1) ]
enabled:@[value;`enabled;0b]            // whether permissions are enabled
maxsize:@[value;`maxsize;200000000]     // the maximum size of any returned result set
readonly:@[value;`.readonly.enabled;0b]
val:$[readonly;reval;eval]
valp:$[readonly;{reval parse x};value]


/ constants
ALL:`$"*";  / used to indicate wildcard/superuser access to functions/data
err.:(::);
err[`func]:{"pm: user role does not permit running function [",string[x],"]"}
err[`selt]:{"pm: no read permission on [",string[x],"]"}
err[`selx]:{"pm: unsupported select statement, superuser only"}
err[`updt]:{"pm: no write permission on [",string[x],"]"}
err[`expr]:{"pm: unsupported expression, superuser only"}
err[`quer]:{"pm: free text queries not permissioned for this user"}
err[`size]:{"pm: returned value exceeds maximum permitted size"}

/ determine whether the system outputs booleans (permission check only) or evaluates query
runmode:@[value;`runmode;1b]

/ determine whether unlisted variables are auto-allowlisted
permissivemode:@[value; `permissivemode; 0b]

/ schema
user:([id:`symbol$()]authtype:`symbol$();hashtype:`symbol$();password:())
groupinfo:([name:`symbol$()]description:())
roleinfo:([name:`symbol$()]description:())
usergroup:([]user:`symbol$();groupname:`symbol$())
userrole:([]user:`symbol$();role:`symbol$())
functiongroup:([]function:`symbol$();fgroup:`symbol$())
access:([]object:`symbol$();entity:`symbol$();level:`symbol$())
function:([]object:`symbol$();role:`symbol$();paramcheck:())
virtualtable:([name:`symbol$()]table:`symbol$();whereclause:())
publictrack:([name:`symbol$()] handle:`int$())

/ api
adduser:{[u;a;h;p]
  if[u in key groupinfo;'"pm: cannot add user with same name as existing group"];
  user,:(u;a;h;p)}
removeuser:{[u]user::.[user;();_;u]}
addgroup:{[n;d]
  if[n in key user;'"pm: cannot add group with same name as existing user"];
  groupinfo,:(n;d)}
removegroup:{[n]groupinfo::.[groupinfo;();_;n]}
addrole:{[n;d]roleinfo,:(n;d)}
removerole:{[n]roleinfo::.[roleinfo;();_;n]}
addtogroup:{[u;g]
  if[not g in key groupinfo;'"pm: no such group, .pm.addgroup first"];
  if[not (u;g) in usergroup;usergroup,:(u;g)];}
removefromgroup:{[u;g]if[(u;g) in usergroup;usergroup::.[usergroup;();_;usergroup?(u;g)]]}
assignrole:{[u;r]
  if[not r in key roleinfo;'"pm: no such role, .pm.addrole first"];
  if[not (u;r) in userrole;userrole,:(u;r)];}
unassignrole:{[u;r]if[(u;r) in userrole;userrole::.[userrole;();_;userrole?(u;r)]]}
addfunction:{[f;g]if[not (f;g) in functiongroup;functiongroup,:(f;g)];}
removefunction:{[f;g]if[(f;g) in functiongroup;functiongroup::.[functiongroup;();_;functiongroup?(f;g)]]}
grantaccess:{[o;e;l]if[not (o;e;l) in access;access,:(o;e;l)]}
revokeaccess:{[o;e;l]if[(o;e;l) in access;access::.[access;();_;access?(o;e;l)]]}
grantfunction:{[o;r;p]if[not (o;r;p) in function;function,:(o;r;p)]}
revokefunction:{[o;r]if[(o;r) in t:`object`role#function;function::.[function;();_;t?(o;r)]]}
createvirtualtable:{[n;t;w]if[not n in key virtualtable;virtualtable,:(n;t;w)]}
removevirtualtable:{[n]if[n in key virtualtable;virtualtable::.[virtualtable;();_;n]]}
addpublic:{[u;h]publictrack::publictrack upsert (u;h)}
removepublic:{[u]publictrack::.[publictrack;();_;u]}
cloneuser:{[u;unew;p] adduser[unew;ul[0] ;ul[1]; value (string (ul:raze exec authtype,hashtype from user where id=u)[1]), " string `", p]; 
 addtogroup[unew;` sv value(1!usergroup)[u]]; 
 assignrole[unew;` sv value(1!userrole)[u]]}

/ permissions check functions
/ making a dictionary of the parameters and the argument values
pdict:{[f;a]
  d:enlist[`]!enlist[::];
  d:d,$[not ca:count a; ();
        f~`select; ();
        (1=count a) and (99h=type first a); first a;
        /if projection first obtain a list of function and fixed parameters (fnfp) 
        104h=type value f; [fnfp:value value f; (value[fnfp 0][1])!fnfp[1],a];
        /get paramaters and make a dictionary with the arguments
        101h<>type fp:value[value[f]][1]; fp!a;
        ((),(`$string til ca))!a
       ];
  d}

fchk:{[u;f;a]
  r:exec role from userrole where user=u;  / list of roles this user has
  o:ALL,f,exec fgroup from functiongroup where function=f; / the func and any groups that contain it
  c:exec paramcheck from function where (object in o) and (role in r);
  k:@[;pdict[f;a];::] each c;  / try param check functions matched for roles
  k:`boolean$@[k;where not -1h=type each k;:;0b];  / errors or non-boolean results treated as false
  max k} / any successful check is sufficient - e.g. superuser trumps failed paramcheck from another role

achk:{[u;t;rw;pr]
  if[fchk[u;ALL;()]; :1b];
  if[pr and not t in key 1!access; :1b];
  t: ALL,t;
  g:raze over (exec groupname by user from usergroup)\[u]; / groups can contain groups - chase all
  exec 0<count i from access where object in t, entity in g, level in (`read`write!(`read`write;`write))[rw]}

/ expression identification
xqu:{(first[x] in (?;!)) and (count[x]>=5)} / Query
xdq:{first[x] in .q} / Dot Q

isq:{(first[x] in (?;!)) and (count[x]>=5)}
query:{[u;q;b;pr]
  if[not fchk[u;`select;()]; $[b;'err[`quer][]; :0b]];  / must have 'select' access to run free form queries
  / update or delete in place
  if[((!)~q[0])and(11h=type q[1]);
    if[not achk[u;first q[1];`write;pr]; $[b;'err[`updt][first q 1]; :0b]];
    $[b; :qexe q; :1b];
  ];
  / nested query
  if[isq q 1; $[b; :qexe @[q;1;.z.s[u;;b;pr]]; :1b]];
  / select on named table
  if[11h=abs type q 1;
     t:first q 1;
     / virtual select
     if[t in key virtualtable;
       vt:virtualtable[t];
       q:@[q;1;:;vt`table];
       q:@[q;2;:;enlist first[q 2],vt`whereclause];
     ];
     if[not achk[u;t;`read;pr]; $[b; 'err[`selt][t]; :0b]];
     $[b; :qexe q; :1b];
  ];
  / default - not specifally handled, require superuser
  if[not fchk[u;ALL;()]; $[b; 'err[`selx][]; :0b]];
  $[b; :qexe q; :1b]}

dotqd:enlist[`]!enlist{[u;e;b;pr]if[not (fchk[u;ALL;()] or fchk[u;`$string(first e);()]);$[b;'err[`expr][]];:0b];$[b;qexe e;1b]};
dotqd[`lj`ij`pj`uj]:{[u;e;b;pr] $[b;val @[e;1 2;expr[u]];1b]}
dotqd[`aj`ej]:{[u;e;b;pr] $[b;val @[e;2 3;expr[u]];1b]}
dotqd[`wj`wj1]:{[u;e;b;pr] $[b;val @[e;2;expr[u]];1b]}

dotqf:{[u;q;b;pr]
  qf:.q?(q[0]);
  p:$[null p:dotqd qf;dotqd`;p];
  p[u;q;b;pr]}

/ flatten an arbitrary data structure, maintaining any strings
flatten:{raze $[10h=type x;enlist enlist x;1=count x;x;.z.s'[x]]}

/ string non-strings, maintain strings
str:{$[10h=type x;;string]x}'

lamq:{[u;e;b;pr]
  / get names of all defined variables to look for references to in expression
  rt:raze .api.varnames[;"v";1b]'[.api.allns[]];
  / allow public tables to always be accessed
  rt:rt except distinct exec object from access where entity=`public;
  / flatten expression & tokenize to extract any possible variable references
  pq:`$distinct -4!raze(str flatten e),'" ";
  / filter expression tokens to those matching defined variables
  rqt:rt inter pq;
  prohibited:rqt where not achk[u;;`read;pr] each rqt;
  if[count prohibited;'" | " sv .pm.err[`selt] each prohibited];
  $[b; :exe e; :1b]}

exe:{v:$[(104<>a)&100<a:abs type first x;val;valp]x;
  if[maxsize<-22!v; 'err[`size][]]; v} 

qexe:{v:val x; if[maxsize<-22!v; 'err[`size][]]; v}

/ check if arg is symbol, and if so if type is <100h i.e. variable - if name invalid, return read error
isvar:{$[-11h<>type x;0b;100h>type @[get;x;{[x;y]'err[`selt][x]}[x]]]}

mainexpr:{[u;e;b;pr]
  / store initial expression to use with value
  ie:e;
  e:$[10=type e;parse e;e];
  / variable reference
  if[isvar f:first e;
    if[not achk[u;f;`read;pr]; $[b;'err[`selt][f]; :0b]];
    :$[b;qexe $[f in key virtualtable;exec (?;table;enlist whereclause;0b;()) from virtualtable[f];e];1b];
  ];
  / named function calls
  if[-11h=type f;
    if[not fchk[u;f;1_ e]; $[b;'err[`func][f]; :0b]];
    $[b; :exe ie; :1b];
  ];
  / queries - select/update/delete
  if[isq e; :query[u;e;b;pr]];
  / .q keywords
  if[xdq e;:dotqf[u;e;b;pr]];
  / lambdas - value any dict args before razing
  if[any (100 104h)in type each raze @[e;where 99h=type'[e];value]; :lamq[u;ie;b;pr]];
  / if we get down this far we don't have specific handling for the expression - require superuser
  if[not (fchk[u;ALL;()] or fchk[u;`$string(first e);()]); $[b;'err[`expr][f]; :0b]];
  $[b; exe ie; 1b]}

/ projection to determine if function will check and execute or return bool, and in second arg run in permissive mode
expr:mainexpr[;;runmode;permissivemode]
allowed:mainexpr[;;0b;0b]

parsequery:{[q]q:$[10=type q;q;10h=abs type f:first q;destringf[f],1_ q;q]};
destringf:{$[(s:`$x)in key`.q;.q s;s~`insert;insert;any (100h; 104h)=type first f: @[parse; x; 0];f;s]};
cando:{[u;q]q:parsequery[q]; $[enabled;allowed[u;q];1b]};
requ:{[u;q]q:parsequery[q]; $[enabled; expr[u;q]; valp q]};
req:{$[.z.w = 0 ; value x; requ[.z.u;x]]}   / entry point - replace .z.pg/.zps

/ authentication

/ methods - must have function for each authtype - e.g. local,ldap
auth.local:{[u;p]
  ud:user[u];
  r:$[`md5~ht:ud`hashtype;
    md5[p]~ud`password;
    0b];  / unknown hashtype
  r}

/ ldap autentication relies on ldap code
auth.ldap:{[u;p]
  / check if ldap has been set up
  $[@[value;`.ldap.enabled;0b];
   .ldap.login[u;p];
   0b]}
 
/ entry point - replace .z.pw 
login:{[u;p]
  if[(not u in key user) or (`public=(1!usergroup)[u][`groupname]);
    if["B"$(.Q.opt .z.x)[`public][0;0]; 
      if[""~p; 
        adduser[u;`local;`md5;(md5 p)]; 
        assignrole[u;`publicuser]; 
        addtogroup[u;`public];
        addpublic[u;.z.w];
        :1b;
      ]];
  :0b]; / todo print log to TorQ?
  ud:user[u];
  if[not ud[`authtype] in key auth;:0b];
  auth[ud`authtype][u;p]}

/ drop public users on logout
droppublic:{[w] 
  if[any "B"$(.Q.opt .z.x)[`public][0;0]; 
    if[0<count publictrack?w;
      u:(value publictrack?w)[0];
      removeuser[u];
      unassignrole[u;`publicuser];
      removefromgroup[u;`public];
      removepublic[u];
      ]]
  }

init:{
  .dotz.set[`.z.ps;{@[x;(`.pm.req;y)]}value .dotz.getcommand[`.z.ps]];
  .dotz.set[`.z.pg;{@[x;(`.pm.req;y)]}value .dotz.getcommand[`.z.pg]];
  // skip permissions for empty lines in q console/qcon
  .dotz.set[`.z.pi;{$[x in (1#"\n";"");.Q.s value x;.Q.s $[.z.w=0;value;req]@x]}];
  .dotz.set[`.z.pp;{'"pm: HTTP POST requests not permitted"}];
  // from V3.5 2019.11.23, .h.val is used in .z.ph to evaluate request; below that disallow .z.ph
  $[(.z.K>=3.5)&.z.k>=2019.11.13;.h.val:req;.dotz.set[`.z.ph;{'"pm: HTTP GET requests not permitted"}]];
  .dotz.set[`.z.ws;{'"pm: websocket access not permitted"}];
  .dotz.set[`.z.pw;login];
  .dotz.set[`.z.pc;{droppublic[y];@[x;y]}value .dotz.getcommand[`.z.pc]];
  }

if[enabled;init[]]

if[enabled;.proc.loadconfig[getenv[`KDBCONFIG],"/permissions/";] each `default,.proc.proctype,.proc.procname;
        if[not ""~getenv[`KDBAPPCONFIG]; .proc.loadconfig[getenv[`KDBAPPCONFIG],"/permissions/";] each `default,.proc.proctype,.proc.procname]]
