// Config for setting Finspace specific parameters
\d .finspace

enabled:@[value;`enabled;0b];                               //whether the application is finspace or on prem - set to false by default
database:@[value;`database;"database"];                     //name of the finspace database applicable to a certain RDB cluster - Not used if on prem
clusters:@[value;`clusters;enlist `cluster];                //list of clusters to be reloaded during the rdb end of day (and possibly other uses)
