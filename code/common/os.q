/- courtesy of Simon Garland
\d .os
NT:.z.o in`w32`w64
Fex:{not 0h~type key hsym$[10=type x;`$x;x]}
pth:{if[10h<>type x;x:string x]; if[NT;x:@[x;where"/"=x;:;"\\"]];$[":"=first x;1_x;x]}
ext:{`$(x?".")_(x:string x;x)[i:10h=type x]}
del:{system("rm ";"del ")[NT],pth x}
deldir:{system("rm -r ";"rd /s /q ")[NT],pth x}
md:{if[not Fex x;system"mkdir \"",pth[x],"\""]};
ren:{system("mv ";"move ")[NT],pth[x]," ",pth y}
cpy:{system("cp ";"copy ")[NT],pth[x]," ",pth y}
Vex:not 0h~type key`.@
df:{(`$("/";"\\")[NT]sv -1_v;`$-1#v:("/";"\\")[NT]vs pth(string x;x)[10h=type x])} 
run:{system"q ",x}
kill:{[p]@[(`::p);"\\\\";1];}
sleep:{x:string x; system("sleep ",x;"timeout /t ",x," >nul")[NT]}
pthq:{[x] $[10h=type x;ssr [x;"\\";"/"];`$ -1 _ ssr [string (` sv x,`);"\\";"/"]]}