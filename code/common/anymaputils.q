.anymap.writetoanymap:{[filepath;data] (hsym filepath) 1: data;};

.anymap.deriveanymapfiles:{[filepath] `$string[filepath],/:("";"#";"##")};

.anymap.util.copyanymap:{[fromfilepath; destfilepath] .os.cpy[;destfilepath] each .anymap.deriveanymapfiles fromfilepath};

.anymap.util.removeanymap:{[filepath] .os.del each .anymap.deriveanymapfiles filepath};

.anymap.util.moveanymap:{[fromfilepath; destfilepath] .os.ren[;destfilepath] each .anymap.deriveanymapfiles fromfilepath};