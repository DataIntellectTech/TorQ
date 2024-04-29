// Config for setting Finspace specific parameters
\d .finspace

enabled:@[value;`enabled;0b];                               //whether the application is finspace or on prem - set to false by default
database:@[value;`database;"database"];                     //name of the finspace database applicable to a certain RDB cluster - Not used if on prem
dataview:@[value;`dataview;"finspace-dataview"];
cache:@[value;`cache;()];
hdbreloadmode:@[value;`hdbreloadmode;"ROLLING"];

hdbclusters:@[value;`hdbclusters;enlist `cluster];          //list of clusters to be reloaded during the rdb end of day (and possibly other uses)
rdbready:@[value;`rdbready;0b];                             //whether or not the rdb is running and ready to take over at the next period- set to false by default

// wrapper around the .aws.get_kx_cluster api
getcluster:{[cluster]
   .lg.o[`getcluster;"getting cluster with name ",string[cluster]];
   resp:@[.aws.get_kx_cluster;string[cluster];{
     msg:"failed to call .aws.get_kx_cluster api due to error: ",-3!x;
     .lg.e[`getcluster;msg];
     `status`msg!("FAILURE";msg)}];
   if[`finspace_error_code in key resp;
      .lg.e[`getcluster;"failed to call .aws.get_kx_cluster api: ",resp[`message]];
      :`status`msg!("FAILURE";resp[`message])];
   :resp
 };

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
      //.lg.o[`notifyhdb;("notifying ",string[cluster]," to repoint to changeset ",changeset[`id])];
      .lg.o[`notifyhdb;("changeset ",changeset[`id]," ready, bringing up new hdb cluster")];
      .lg.o[`notifyhdb;"new changeset ready. create new hdb"];
      // TODO - Also need to figure out the ideal logic if a changeset fails to create. Possibly recreate and re-run notifyhd
   }

// function to close connection to TP and remove unwanted data in WDB and RDB's 
eopdatacleanup:{[dict]
    // close off each subsription by handle to the tickerplant  
    hclose each distinct exec w from .sub.SUBSCRIPTIONS;
    // function to parse icounts dict and remove all data after a given index for RDB and WDB's 
    {[t;ind]delete from t where i >= ind}'[key dict;first each value dict];
 }
//set rdbready to true after signal received from the old rdb, that new processes are running and ready to take over at start of new period
newrdbup:{[]
      .lg.o[`newrdbup;"received signal from next period rdb, setting rdbready to true"];
      @[`.finspace;`rdbready;:;1b];
 };

deletecluster:{[clustername]
  if[not any (10h;-11h)=fType:type clustername; .lg.e[`deletecluster;"clustername must be of type string or symbol: 10h -11h, got ",-3!fType]; :(::)];
  if[-11h~fType; clustername:string clustername];
  .lg.o[`deletecluster;"Going to delete ",$[""~clustername;"current cluster";"cluster named: ",clustername]];
  .aws.delete_kx_cluster[clustername]; // calling this on an empty string deletes self
  // TODO ZAN Error trap
  // Test this with invalid cluster names and catch to show error messages
  };
