/- courtesy of Simon Garland
\d .os
NT:.z.o in`w32`w64
Fex:{not 0h~type key hsym$[10=type x;`$x;x]}
pth:{if[10h<>type x;x:string x]; if[NT;x:@[x;where"/"=x;:;"\\"]];$[":"=first x;1_x;x]}
ext:{`$(x?".")_(x:string x;x)[i:10h=type x]}
del:{system("rm ";"del ")[NT],pth x}
deldir:{system("rm -r ";"rd /s /q ")[NT],pth x}
hdeldir:{[dirpath;pdir]
 dirpath:$[10h=a:type dirpath;dirpath;-11h=a;string dirpath;'`type];
 diR:{$[11h=type d:key x;raze x,.z.s each` sv/:x,/:d;d]};
 filelist:diR hsym`$dirpath;
 if[not pdir;filelist:1_filelist];
 .lg.o[`deldir;"deleting from  directory : ",dirpath];
 hdel each desc filelist}
md:{if[not Fex x;system"mkdir \"",pth[x],"\""]};
cpy:{system("cp ";"copy ")[NT],pth[x]," ",pth y}
Vex:not 0h~type key`.@
df:{(`$("/";"\\")[NT]sv -1_v;`$-1#v:("/";"\\")[NT]vs pth(string x;x)[10h=type x])} 
run:{system"q ",x}
kill:{[p]@[(`::p);"\\\\";1];}
sleep:{x:string x; system("sleep ",x;"timeout /t ",x," >nul")[NT]}
pthq:{[x] $[10h=type x;ssr [x;"\\";"/"];`$ -1 _ ssr [string (` sv x,`);"\\";"/"]]}
ren:{[x;y]
 / Convert the incoming q values into OS path strings.
 src:pth x;
 dst:pth y;
 / On non-Windows platforms a normal mv already handles file and directory renames.
 if[not NT;
  :system "mv \"",src,"\" \"",dst,"\""];
 / Escape single quotes so a path can be embedded safely in a PowerShell literal string.
 psqlit:{[p] "'",ssr[p;"'";"''"],"'"};
 / Move-Item gives us native Windows move semantics for files, directories and cross-volume moves.
 :system "powershell -NoProfile -Command Move-Item -LiteralPath ",psqlit[src]," -Destination ",psqlit[dst]}