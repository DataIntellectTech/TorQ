// Add to the api functions

\d .api

if[not`add in key `.api;add:{[name;public;descrip;params;return]}]

add[`.rdb.moveandclear;1b;"Move a variable (table) from one namespace to another, deleting its contents.  Useful during the end-of-day roll down for tables you do not want to save to the HDB";"[symbol: the namespace to move the table from; symbol:the namespace to move the variable to; symbol: the name of the variable]";"null"]
