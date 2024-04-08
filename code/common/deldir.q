//recursively delete contents of directory using hdel
deldir:{[dirpath]
 diR:{$[11h=type d:key x;raze x,.z.s each` sv/:x,/:d;d]};
 nuke:hdel each desc diR@;
 nuke hsym`$dirpath;
 .lg.o[`deldir;"deleting from  directory"]
        }
