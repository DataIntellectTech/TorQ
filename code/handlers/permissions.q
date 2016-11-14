
\d .pm

if[@[1b; `.access.enabled;0b]; ('"controlaccess.q already active";exit 1) ]
if[not @[value;`.proc.loaded;0b]; '"environment is not initialised correctly to load this script"]

MAXSIZE:@[value;`MAXSIZE;200000000]     // the maximum size of any returned result set
enabled:@[value;`enabled;1b]            // whether permissions are enabled
openonly:@[value;`openonly;0b]          // only check permissions when the connection is made, not on every call

/ constants
ALL:`$"*";  / used to indicate wildcard/superuser access to functions/data
err.:(::);
err[`func]:{"pm: user role does not permit running function [",string[x],"]"}
err[`selt]:{"pm: no read permission on [",string[x],"]"}
err[`selx]:{"pm: unsupported select statement, superuser only"}
err[`updt]:{"pm: no write permission on [",string[x],"]"}
err[`expr]:{"pm: unsupported expression, superuser only"}
err[`quer]:{"pm: free text queries not permissioned for this user"}
 


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
superroles: `symbol$(); // roles where parameter should not be checked													
ignoredfunctions: `symbol$();  //functions where parameters should not be checked	

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
addsuperrole:{[r]if[(superroles?r) = count superroles; superroles,:r] }
removesuperrole:{[r]if[not (superroles?r) = count superroles; superroles:: superroles except r] }
addignoredfunction:{[o]if[(ignoredfunctions?o) = count ignoredfunctions; ignoredfunctions,:o]}
removeignoredfunction:{[r]if[not (ignoredfunctions?o) = count ignoredfunctions; ignoredfunctions:: ignoredfunctions except o] }

/ clone user looks for an original user u, and adds a new user with a new password and everything else the same as user u.
cloneuser:{[u;unew;p] adduser[unew;ul[0] ;ul[1]; value (string (ul:raze exec authtype,hashtype from user where id=u)[1]), " string `", p];
  addtogroup[unew;` sv value(1!usergroup)[u]];
  assignrole[unew;` sv value(1!userrole)[u]]}

/ permissions check functions

/ Can the function be called without the parameters being checked 
prmtrlss:{[u;f]
  r:exec role from userrole where user=u;
  uf:select from function where (object = f) and (role in r);
  if[not 0 = count uf; $[not (first superroles?r)= count superroles; :1b; if[not (first ignoredfunctions?o) = count ignoredfunctions;:1b]]];
  0b}
pdict:{[f;a]
  d:enlist[`]!enlist[::];
  d:d,$[not count a;();f~`select;();(1=count a) and (99h=type first a);first a;get[get[f]][1]!a];
  d}

fchk:{[u;f;a]
  r:exec role from userrole where user=u;  / list of roles this user has
  o:ALL,f,exec fgroup from functiongroup where function=f; / the func and any groups that contain it
  c:exec paramcheck from function where (object in o) and (role in r);
  if[1 = count c; if[ 1b = c[0;0]; :1b]];
  k:@[;pdict[f;a];::] each c;  / try param check functions matched for roles
  k:`boolean$@[k;where not -1h=type each k;:;0b];  / errors or non-boolean results treated as false
  max k} / any successful check is sufficient - e.g. superuser trumps failed paramcheck from another role

achk:{[u;t;rw]
  g:raze over (exec groupname by user from usergroup)\[u]; / groups can contain groups - chase all
  exec 0<count i from access where object=t, entity in g, level in (`read`write!(`read`write;`write))[rw]}

/ expression identification
xqu:{(first[x] in (?;!)) and (count[x]>=5)} / Query
xdq:{first[x] in .q} / Dot Q

isq:{(first[x] in (?;!)) and (count[x]>=5)}
query:{[u;q;b]
  if[not fchk[u;`select;()]; $[b;'err[`quer][]; :0b]];  / must have 'select' access to run free form queries
  / update or delete in place
  if[((!)~q[0])and(11h=type q[1]); 
    if[fchk[u;ALL;()]; $[b; :eval q; :1b]]; / admin can modify any table first 
    if[not achk[u;first q[1];`write]; $[b;'err[`updt][first q 1]; :0b]];
    $[b; :eval q; :1b];
  ];
  / nested query
  if[isq q 1; $[b; :eval @[q;1;.z.s[u;;b]]; :1b]];
  / select on named table
  if[11h=abs type q 1;
     t:first q 1;
     / virtual select 
     if[t in key virtualtable;
       vt:virtualtable[t];
       q:@[q;1;:;vt`table];
       q:@[q;2;:;enlist first[q 2],vt`whereclause]; 
     ];
     if[fchk[u;ALL;()]; $[b; :eval q; :1b]]; / admin can look at any table 
     if[not achk[u;t;`read]; $[b; 'err[`selt][t]; :0b]];
     $[b; :eval q; :1b];
  ];
  / default - not specifally handled, require superuser
  if[not fchk[u;ALL;()]; $[b; 'err[`selx][]; :0b]];
  $[b; :eval q; :1b]}

     
dotqd:enlist[`]!enlist{[u;e;b]if[not fchk[u;ALL;()];$[b;'err[`expr][]];:0b];$[b;exe e;1b]};
dotqd[`lj`ij`pj`uj]:{[u;e;b] $[b;eval @[e;1 2;expr[u]];1b]}
dotqd[`aj`ej]:{[u;e;b] $[b;eval @[e;2 3;expr[u]];1b]}
dotqd[`wj`wj1]:{[u;e;b] $[b;eval @[e;2;expr[u]];1b]}

dotqf:{[u;q;b]
  qf:.q?(q[0]);
  p:$[null p:dotqd qf;dotqd`;p];
  p[u;q;b]}

lamq:{[u;e;l]
    rt:(distinct exec object from access where entity<>`public);
    rqt:rt where rt in (raze `$distinct {-4!x} each string raze/[{any (type each x) within (0;99)};e]);
    prohibited: rqt where not achk[u;;`read] each rqt;
    if[count prohibited;'" | " sv .pm.err[`selt] each prohibited];
  :exe e}

exe:{if[99<abs type first x; :eval x]; value x} /account for complex calls, e.g. "in"

mainexpr:{[u;e;b]
  / variable reference
  if[-11h=type e;
    if[fchk[u;ALL;()]; $[b; :eval e; :1b]]; / admin can modify any table first 
    if[not achk[u;e;`read]; $[b;'err[`selt][e]; :0b]];
    $[b; :eval $[e in key virtualtable;exec (?;table;enlist whereclause;0b;()) from virtualtable[e];e]; :1b];
  ];
  / named function calls
  if[-11h=type f:first e;
    if[not fchk[u;f;1_ e]; $[b;'err[`func][f]; :0b]];
    if[not all type'[e]; e:raze e]; /some methods of passing args enlist in parse
    if[any count'[e]=signum type'[e]; e:raze e]; /catch single enlisted and raze
    $[b; :exe e; :1b];
  ];
  / queries - select/update/delete
  if[isq e; :query[u;e;b]];
  / .q keywords
  if[xdq e;:dotqf[u;e;b]];
  /lambdas
  if[any lam:100=type each raze e; :lamq[u;e;lam]];
  / if we get down this far we don't have specific handling for the expression - require superuser
  if[not fchk[u;ALL;()]; $[b;'err[`expr][f]; :0b]];
  $[b; exe e; 1b]}

/ projection to determine if function will check and execute or return bool
expr:mainexpr[;;1b]
allowed:mainexpr[;;0b]

destringf:{$[(x:`$x)in key`.q;.q x;x~`insert;insert;x]}
requ:{[u;q]q:$[10=type q;parse q;$[10h=abs type f:first q;destringf[f],1_ q;q]];if[prmtrlss[u; first q]; .Q.s value x]; expr[u;q]};
////requ:{[u;q]allowed[u] q:$[10=type q;parse q;$[10h=type f:first q;destringf[f],1_ q;q]]};
req:{$[.z.w = 0 ; .Q.s value x; requ[.z.u;x]]}   / entry point - replace .z.pg/.zps
  
/ authentication

/ methods - must have function for each authtype - e.g. local,ldap
auth.local:{[u;p]
  ud:user[u];
  r:$[`md5~ht:ud`hashtype;
    md5[p]~ud`password;
    0b];  / unknown hashtype
  r}
 
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

droppublic:{[w] 
  if["B"$(.Q.opt .z.x)[`public][0;0]; 
    if[0<count publictrack?w;
      u:(value publictrack?w)[0];
      removeuser[u];
      unassignrole[u;`publicuser];
      removefromgroup[u;`public];
      removepublic[u];
      ]]
  }

init:{
  .z.pg:.z.ps:req;
  .z.pi:{$[x~enlist"\n";.Q.s value x;.Q.s $[.z.w=0;value;req]@x]}; 
  .z.pw:login;
  .z.pc:droppublic;
  }

if[enabled;init[]]
