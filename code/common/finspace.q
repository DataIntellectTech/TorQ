// Config for setting Finspace specific parameters
\d .finspace

enabled:@[value;`enabled;0b];                               //whether the application is finspace or on prem - set to false by default
database:@[value;`database;"database"];                     //name of the finspace database applicable to a certain RDB cluster - Not used if on prem
hdbclusters:@[value;`hdbclusters;enlist `cluster];          //list of clusters to be reloaded during the rdb end of day (and possibly other uses)

/ Runs a .aws api until a certain status has been received
checkStatus:{[apiCall;status;frequency;timeout]
  res:value apiCall;
  st:.z.t;
  l:0;
  while[(timeout>ti:.z.t-st) & not any (res`status) like/: status; 
     if[frequency<=ti-l;
            l:ti;
            res:value apiCall; 
            .lg.o[`checkStatus;"Status: ", (res`status), " waited: ", string(ti)];
     ];
   ];
   .lg.o[`checkStatus;"Status: ",(res`status)];
   :res; 
 };

// Creates a Finspace changeset during the RDB end of day process
createChangeset:{[db]
      .lg.o[`createChangeset;"downloading sym file to scratch directory for ",db];
      .aws.get_latest_sym_file[db;getenv[`KDBSCRATCH]];
      .lg.o[`createChangeset;"creating changeset for database: ", db];
      details:.aws.create_changeset[db;([]input_path:enlist getenv[`KDBSCRATCH];database_path:enlist "/";change_type:enlist "PUT")];
      .lg.o[`createChangeset;("creating changset ",(details`id)," with initial status of ",(details`status))];
      :details;
  };


// Notifies the HDB clusters to repoint to the new changeset once it has finished creating
notifyhdb:{[cluster;changeset]
      
      .lg.o[`notifyhdb;"Checking status of changeset ",(changeset`id)];
      
      // Ensuring that the changeset has successfully created before doing the HDB reload
      current:.finspace.checkStatus[(`.aws.get_changeset;.finspace.database;changeset`id);("COMPLETED";"FAILED");00:01;0wu];
      .lg.o[`notifyhdb;("notifying ",(string[cluster])," to repoint to changeset ",(changeset`id))];
      // TODO - Once the status of the changeset is "COMPLETED" we need to run the aws HDB reload API (once it is available)
      // TODO - Also need to figure out the ideal logic if a changeset fails to create. Possibly recreate and re-run notifyhd
   }

