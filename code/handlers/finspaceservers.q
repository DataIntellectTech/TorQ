.servers.FINSPACEDISC:@[value; `.servers.FINSPACEDISC; 0b];
.servers.FINSPACECLUSTERSFILE:@[value; `.servers.FINSPACECLUSTERSFILE; hsym `];

.servers.readclustersfile:{[]
    if[null .servers.FINSPACECLUSTERSFILE; {.lg.e[`readclustersfile; "no finspace clusters file defined"]}];
    :("SSSS**"; enlist ",") 0: .servers.FINSPACECLUSTERSFILE;
    };

.servers.getfinspaceclusters:{[]
    expclusters:@[.servers.readclustersfile; `; {.lg.e[`getfinspaceclusters; "Failed to get read clusters.csv when using -  ",x]}];
    availclusters:@[.aws.list_kx_clusters; `; {.lg.e[`getfinspaceclusters; "Failed to get finspace clusters using the finspace API - ",x]}];
    :expclusters ij `cluster_name`cluster_type xkey select `$cluster_name, `$cluster_type, `$status from availclusters where status like "RUNNING";
    };

.servers.getfinspaceconn:{[ptype; pname]
    id:.j.j[(ptype;pname)];
    cluster:first exec cluster_name from .servers.getfinspaceclusters[] where proctype=ptype, procname = pname;

    if[null cluster; .lg.w[`finspaceconn; "no available finspace cluster found for ",id]; :`];
    conn:@[.aws.get_kx_connection_string; cluster; {[id;e] .lg.e[`finspaceconn; "failed to get connection string for ",id," via aws api - ",e]; :`}[id;]];
    :`$conn;
    };
