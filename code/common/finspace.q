// Config for setting Finspace specific parameters
\d .finspace

enabled:@[value;`enabled;0b];                               //whether the application is finspace or on prem - set to false by default
database:@[value;`database;"database"];                     //name of the finspace database applicable to a certain RDB cluster - Not used if on prem
hdbclusters:@[value;`hdbclusters;enlist `cluster];          //list of clusters to be reloaded during the rdb end of day (and possibly other uses)

// Creates a Finspace changeset during the RDB end of day process
createChangeset:{[db]
      .lg.o[`createChangeset;"creating changeset for database: ", db];
      details:.aws.create_changeset[db;([]input_path:enlist getenv[`KDBSCRATCH];database_path:enlist "/";change_type:enlist "PUT")];
      .lg.o[`createChangeset;("creating changset ",(details`id)," with initial status of ",(details`status))];
      :details;
  };


// Notifies the HDB clusters to repoint to the new changeset once it has finished creating
notifyhdb:{[cluster;changeset]
      stts:1;
      while[stts;
               current:(.aws.get_changeset[.finspace.database;changeset`id])`status;
               .lg.o[`notifyhdb;("current status of changeset ",(changeset`id)," is ",(current))]
               if["COMPLETED" ~ current;
                       stts:0
               ];        
      ];
      .lg.o[`notifyhdb;("notifying ",(string[cluster])," to repoint to changeset ",(changeset`id))];
      // TODO - Once the status of the changeset is "COMPLETED" we need to run the aws HDB reload API (once it is available)
  };
