//- log requests made to DA API
.dataaccess.logging:@[value;`.dataaccess.logging;1b];
.dataaccess.stats:([querynumber:()]user:();starttime:();endtime:();handle:();request:();success:();error:());


\d .requests        

initlogger:{[inputparams]
  // Get the request number
  if[not .dataaccess.logging;:-1]
  reqno:1+count .dataaccess.stats;
  `.dataaccess.stats upsert (reqno;.z.u;.z.p;.z.p;.z.w;inputparams;1b;`);
  :reqno
  };

updatelogger:{[reqno;swapdict]
    if[reqno=-1;:-1];
    .dataaccess.stats[reqno]::.dataaccess.stats[reqno] upsert swapdict;
    :-1;
    };

error:{[reqno;error]
    if[reqno=-1;'error];
    updatelogger[reqno;`endtime`error`success!(.proc.cp[];`$error;0b)];
    'error;
    };
