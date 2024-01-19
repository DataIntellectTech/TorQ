.servers.FINSPACEDISC:@[value; `.servers.FINSPACEDISC; 0b];
.servers.FINSPACECLUSTERSFILE:@[value; `.servers.FINSPACECLUSTERSFILE; hsym `];

.servers.listfinspaceclusters:{
    :@[.aws.list_kx_clusters; `; {.lg.e[`listfinspaceclusters; "Failed to get finspace clusters using the finspace API - ",x]}];
    };

.servers.getfinspaceconn:{[pname]
    id:.Q.s1 pname;
    runningclusters:select `$cluster_name, `$cluster_type, status from .servers.listfinspaceclusters[] where status like "RUNNING";
    cluster:first exec cluster_name from runningclusters where pname = cluster_name;

    if[null cluster; .lg.w[`finspaceconn; "no available finspace cluster found for ",id]; :`];
    conn:@[.aws.get_kx_connection_string; cluster; {[id;e] .lg.e[`finspaceconn; "failed to get connection string for ",id," via aws api - ",e]; :`}[id;]];
    :`$conn;    
    };