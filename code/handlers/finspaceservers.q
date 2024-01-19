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

/
.servers.readclustersfile:{[]
    if[null .servers.FINSPACECLUSTERSFILE; {.lg.e[`readclustersfile; "no finspace clusters file defined"]}];
    :("SSSS**"; enlist ",") 0: .servers.FINSPACECLUSTERSFILE;
    };


.servers.getfinspaceclusters:{[]
    expclusters:@[.servers.readclustersfile; `; {.lg.e[`getfinspaceclusters; "Failed to get read clusters.csv when using -  ",x]}];
    availclusters:.servers.listfinspaceclusters[];
    runclusters:select `$cluster_name, `$cluster_type, `$status, description from availclusters where status like "RUNNING";
    :runclusters lj `cluster_name`cluster_type xkey expclusters
    };

.servers.getfinspaceconn:{[ptype; pname]
    id:.j.j[(ptype;pname)];
    clusters:.servers.getfinspaceclusters[];
    cluster:(first exec cluster_name from clusters where proctype=ptype, procname = pname) ^ (first exec cluster_name from clusters where pname in/: `$" " vs/: description);

    if[null cluster; .lg.w[`finspaceconn; "no available finspace cluster found for ",id]; :`];
    conn:@[.aws.get_kx_connection_string; cluster; {[id;e] .lg.e[`finspaceconn; "failed to get connection string for ",id," via aws api - ",e]; :`}[id;]];
    :`$conn;
    };

