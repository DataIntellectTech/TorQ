\d .query

handles:`::12757:angus:pass`::12757:michael:pass`::12757:stephen:pass;
dbs:`hdb`rdb;
queries:([] db:asc 20#`hdb`rdb; query:(
    "select max price by sym from trade where date=z.d - 1"; "select min price by sym from trade where date=z.d - 1"; "select distinct sym from trade where date=z.d - 1"; "select avg size by side from trade where date=z.d - 1"; "select first price by sym from trade where date=z.d - 1"; "select last price by sym from trade where date=z.d - 1"; "select asize:avg asize by sym, src from quote where date=z.d - 1"; "select bsize:avg bsize by sym, src from quote where date=z.d - 1"; "select distinct sym by ex from quote where date=z.d - 1"; "select avgspread:avg ask - bid by sym from quote where date=z.d - 1"; 
    "select max price by sym from trade"; "select min price by sym from trade"; "select distinct sym from trade"; "select avg size by side from trade"; "select first price by sym from trade"; "select last price by sym from trade"; "select asize:avg asize by sym, src from quote"; "select bsize:avg bsize by sym, src from quote"; "select distinct sym by ex from quote"; "select avgspread:avg ask - bid by sym from quote"));

h:hopen each handles;

execute:{
    handle:first -1?h;
    db:first -1?dbs;
    query:last flip -1?select from queries where db=db;

    neg[handle](`.gw.asyncexec; query; db);
    };

\d .

.timer.repeat[.proc.cp[]; 0Wp; 0D00:00:02; (`.query.execute;`); "Execute fake queries"];
