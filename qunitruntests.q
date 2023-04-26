/we move into the qunit namespace
system"d .qunit";

/we get a list of all qfiles in the test directory
qfiles:allfiles where (string each allfiles:key hsym dir:first `$.proc.params[`test]) like "*.q*";

/we load in each of these .q files
system each raze'["l ",/:string[dir],/:"/",/:string qfiles];

/we find all namespaces in the root, which contain Test, and run the testing function on them, which prints the results
show each .qunit.runTests each .Q.dd[`] each ns[where (string each ns:key `) like "*Test*"]
