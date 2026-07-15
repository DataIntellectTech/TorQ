.anymap.writetoanymap:{[filepath;data] (hsym filepath) 1: data; :(::)}
.anymap.deriveanymapfiles:{[filepath] `$string[filepath],/:("";"#";"##")}
.anymap.util.copyanymap:{[fromfilepath; destfilepath] fromfilepaths:.anymap.deriveanymapfiles[fromfilepath]; .os.cpy[;destfilepath] each fromfilepaths)}
.anymap.util.removeanymap:{[filepath] filepaths:.anymap.deriveanymapfiles[filepath]; .os.del each filepaths)}
.anymap.util.moveanymap:{[fromfilepath; destfilepath] fromfilepaths:.anymap.deriveanymapfiles[fromfilepath]; .os.ren[;destfilepath] each fromfilepaths)}
