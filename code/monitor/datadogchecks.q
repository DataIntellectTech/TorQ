\d .dg

//send result of check from monitor process to datadog agent
sendresultmetric:{[p;r] sendmetric["torqup.",(string `..checkconfig[r`checkid]`process);r`result];`..truefalse[p;r]}
