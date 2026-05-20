.anymap.writeToAnyMap:{[data;filePath] (hsym filePath) 1: data; :(::)}
.anymap.deriveAnymapFiles:{[filePath] strPath: string[filePath]; `$(strPath;strPath,"#";strPath,"##")}
.anymap.util.copyAnyMap:{[fromFilePath; destFilePath] fromFilePaths:.anymap.deriveAnymapFiles[fromFilePath]; system (("cp "," " sv string fromFilePaths), " ", string destFilePath)}
.anymap.util.removeAnyMap:{[filePath] filePaths:.anymap.deriveAnymapFiles[filePath]; system ("rm "," " sv string filePaths)}
.anymap.util.moveAnyMap:{[fromFilePath; destFilePath] fromFilePaths:.anymap.deriveAnymapFiles[fromFilePath]; system (("mv "," " sv string fromFilePaths), " ", string destFilePath)}