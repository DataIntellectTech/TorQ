system"d .qunit";
c:b where (string each b:key hsym d:first `$.proc.params[`test]) like "*.q*";
system each raze'["l ",/:string[d],/:"/",/:string c];
show each .qunit.runTests each .Q.dd[`] each a[where (string each a:key `) like "*Test*"]
