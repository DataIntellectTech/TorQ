.servers.FINSPACEDISC:@[value; `.servers.FINSPACEDISC; 0b];
.servers.FINSPACECLUSTERSFILE:@[value; `.servers.FINSPACECLUSTERSFILE; hsym `];
.servers.REFRESHONSTARTPROCS:enlist `hdb;

.servers.listfinspaceclusters:{
    :@[.aws.list_kx_clusters; `; {.lg.e[`listfinspaceclusters; "Failed to get finspace clusters using the finspace API - ",x]}];
    };

.servers.getfinspaceconn:{[pname]
    id:.Q.s1 pname;
    cluster:first exec `$cluster_name from .servers.listfinspaceclusters[] where status like "RUNNING",(`$cluster_name)=pname;

    if[null cluster; .lg.w[`finspaceconn; "no available finspace cluster found for ",id]; :`];
    conn:@[.aws.get_kx_connection_string; cluster; {[id;e] .lg.e[`finspaceconn; "failed to get connection string for ",id," via aws api - ",e]; :`}[id;]];
    :`$conn;
    };

// do not refresh the connection if the handle in question is in the process of being deregistered
.servers.refreshconntoprocgatewaychk:{[gwh;row]
   func:{[r]
     h:first exec w from .servers.SERVERS where i = r;
     $[(null h) or h in @[value;`.finspace.deregserverids;()]; 0b; 1b]
   };
   gwh(func;row)
 };

.servers.refreshconntoprocfromdiscoveryhelper:{[tgt;dict]
    h:dict[`w];
    tgtidx:first @[h;({exec i from .servers.SERVERS where procname=x};tgt);()];
    if[null tgtidx; :()];
    .lg.o[`refreshconntoprocfromdiscovery;"tgtidx in servers.SERVERS for process ",(string dict[`procname])," is ",-3!tgtidx];
    doretry: $[dict[`procname] like "gateway*"; .servers.refreshconntoprocgatewaychk[h;tgtidx]; 1b]; //gateway special case
    if[doretry; [neg h](`.servers.retryrows;tgtidx)]; 
 };

.servers.refreshconntoprocfromdiscovery:{[targetproc;sourceprocs]
  if[not (fType:type targetproc) in -11h; .lg.o[`refreshconntoprocfromdiscovery;"targetproc must be a symbol. Got ",-3!fType]; :()];
  if[not (fType:type sourceprocs) in (11h;-11h); .lg.o[`refreshconntoprocfromdiscovery;"sourceprocs must be a symbol or list of symbols. Got ",-3!fType]; :()];
  //if[not .proc.proctype in .servers.REFRESHONSTARTPROCS; .lg.o[`refreshconntoprocfromdiscovery;"proctype ",(string .proc.proctype)," will not force refresh connections on startup"]; :()];

  if[`Any~sourceprocs; sourceprocs:`];
  sources:select procname,w from .servers.getservers[`proctype;sourceprocs;()!();1b;0b] where procname<>targetproc;
   
  .servers.refreshconntoprocfromdiscoveryhelper[targetproc;] each sources;
 };