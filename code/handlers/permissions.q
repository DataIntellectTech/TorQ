
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

/ determine whether unlisted variables are auto-whitelisted
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
adduser:{[u;a;h;p]user,:(u;a;h;p)}
removeuser:{[u]user::.[user;();_;u]}
addgroup:{[n;d]groupinfo,:(n;d)}
removegroup:{[n]groupinfo::.[groupinfo;();_;n]}
addrole:{[n;d]roleinfo,:(n;d)}
removerole:{[n]roleinfo::.[roleinfo;();_;n]}
addtogroup:{[u;g]if[not (u;g) in usergroup;usergroup,:(u;g)];}
removefromgroup:{[u;g]if[(u;g) in usergroup;usergroup::.[usergroup;();_;usergroup?(u;g)]]}
assignrole:{[u;r]if[not (u;r) in userrole;userrole,:(u;r)];}
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

pdict:{[f;a]
  d:enlist[`]!enlist[::];
  /checking for parameters,projection
  d:d,$[not ca:count a;();f~`select;();(1=count a) and (99h=type first a);first a;101h<>type fp:get[get[f]][1]; fp!a; ((),(`$string til ca))!a];
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

dotqd:enlist[`]!enlist{[u;e;b;pr]if[not (fchk[u;ALL;()] or fchk[u;`$string(first e);()]);$[b;'err[`expr][]];:0b];$[b;exe e;1b]};
dotqd[`lj`ij`pj`uj]:{[u;e;b;pr] $[b;val @[e;1 2;expr[u]];1b]}
dotqd[`aj`ej]:{[u;e;b;pr] $[b;val @[e;2 3;expr[u]];1b]}
dotqd[`wj`wj1]:{[u;e;b;pr] $[b;val @[e;2;expr[u]];1b]}

dotqf:{[u;q;b;pr]
  qf:.q?(q[0]);
  p:$[null p:dotqd qf;dotqd`;p];
  p[u;q;b;pr]}

lamq:{[u;e;l;b;pr]
  rt:(distinct exec object from access where entity<>`public); / allow public tables 
  pq:(raze `$distinct {-4!x} (raze/)(s:raze each string e) ,' " ");
  rqt:rt where rt in pq;
  prohibited: rqt where not achk[u;;`read;pr] each rqt;
  if[count prohibited;'" | " sv .pm.err[`selt] each prohibited];
  $[b; :exe e; :1b]}

exe:{if[(100<abs type first x); v:val x]; v:valp x;
  if[maxsize<-22!v; 'err[`size][]]; v} 

qexe:{v:val x; if[maxsize<-22!v; 'err[`size][]]; v}

mainexpr:{[u;e;b;pr]
  / store initial expression to use with value
  ie:e;
  e:$[10=type e;parse e;e];
  / variable reference
  if[-11h=type e;
    if[not achk[u;e;`read;pr]; $[b;'err[`selt][e]; :0b]];
    $[b; :qexe $[e in key virtualtable;exec (?;table;enlist whereclause;0b;()) from virtualtable[e];e]; :1b];
  ];
  / named function calls
  if[-11h=type f:first e;
    if[not fchk[u;f;1_ e]; $[b;'err[`func][f]; :0b]];
    $[b; :exe ie; :1b];
  ];
  / queries - select/update/delete
  if[isq e; :query[u;e;b;pr]];
  / .q keywords
  if[xdq e;:dotqf[u;e;b;pr]];
  / lambdas
  if[any lam:100=type each raze e; :lamq[u;ie;lam;b;pr]];
  / if we get down this far we don't have specific handling for the expression - require superuser
  if[not (fchk[u;ALL;()] or fchk[u;`$string(first e);()]); $[b;'err[`expr][f]; :0b]];
  $[b; exe ie; 1b]}

/ projection to determine if function will check and execute or return bool, and in second arg run in permissive mode
expr:mainexpr[;;runmode;permissivemode]
allowed:mainexpr[;;0b;0b]

parsequery:{[q]q:$[10=type q;q;10h=abs type f:first q;destringf[f],1_ q;q]}
destringf:{$[(x:`$x)in key`.q;.q x;x~`insert;insert;x]}
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
  .z.ps:{@[x;(`.pm.req;y)]}.z.ps;
  .z.pg:{@[x;(`.pm.req;y)]}.z.pg;
  .z.pi:{$[x~enlist"\n";.Q.s value x;.Q.s $[.z.w=0;value;req]@x]}; 
  .z.pp:.z.ph:{'"pm: HTTP requests not permitted"};
  .z.ws:{'"pm: websocket access not permitted"};
  .z.pw:login;
  .z.pc:{droppublic[y];@[x;y]}.z.pc;
  }

if[enabled;init[]]

if[enabled;.proc.loadconfig[getenv[`KDBCONFIG],"/permissions/";] each `default,.proc.proctype,.proc.procname;
        if[not ""~getenv[`KDBAPPCONFIG]; .proc.loadconfig[getenv[`KDBAPPCONFIG],"/permissions/";] each `default,.proc.proctype,.proc.procname]]
