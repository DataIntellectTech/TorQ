// Config for setting Finspace specific parameters
\d .finspace

enabled:@[value;`enabled;0b];                               //whether the application is finspace or on prem - set to false by default
database:@[value;`database;"database"];                     //name of the finspace database applicable to a certain RDB cluster - Not used if on prem

hdbclusters:@[value;`hdbclusters;enlist `cluster];          //list of clusters to be reloaded during the rdb end of day (and possibly other uses)

/ Runs a .aws api until a certain status has been received
checkstatus:{[apicall;status;frequency;timeout]
  res:value apicall;
  st:.z.t;
  l:0;
  while[(timeout>ti:.z.t-st) & not any res[`status] like/: status; 
     if[frequency<=ti-l;
            l:ti;
            res:value apicall; 
            .lg.o[`checkstatus;"Status: ", res[`status], " waited: ", string(ti)];
     ];
   ];
   .lg.o[`checkstatus;"Status: ",res[`status]];
   :res; 
 };

// Creates a Finspace changeset during the RDB end of day process
createchangeset:{[db]
      .lg.o[`createchangeset;"creating changeset for database: ", db];
      details:.aws.create_changeset[db;([]input_path:enlist getenv[`KDBSCRATCH];database_path:enlist "/";change_type:enlist "PUT")];
      .lg.o[`createchangeset;("creating changset ",details[`id]," with initial status of ",details[`status])];
      :details;
  };

// Notifies the HDB clusters to repoint to the new changeset once it has finished creating
notifyhdb:{[cluster;changeset]
      
      .lg.o[`notifyhdb;"Checking status of changeset ",changeset[`id]];
      
      // Ensuring that the changeset has successfully created before doing the HDB reload
      current:.finspace.checkstatus[(`.aws.get_changeset;.finspace.database;changeset[`id]);("COMPLETED";"FAILED");00:01;0wu];
      .lg.o[`notifyhdb;("notifying ",string[cluster]," to repoint to changeset ",changeset[`id])];
      .aws.update_kx_cluster_databases[string[cluster];.aws.sdbs[.aws.db[.finspace.database;changeset[`id];.aws.cache["CACHE_1000";"/"]]];.aws.sdep["NO_RESTART"]]
      // TODO - Also need to figure out the ideal logic if a changeset fails to create. Possibly recreate and re-run notifyhd
   }

// function to close connection to TP and remove unwanted data in WDB and RDB's 
eopdatacleanup:{[dict]
    // close off each subsription by handle to the tickerplant  
    hclose each distinct exec w from .sub.SUBSCRIPTIONS;
    // function to parse icounts dict and remove all data after a given index for RDB and WDB's 
    {[t;ind]delete from t where i >= ind}'[key dict;first each value dict];
 }