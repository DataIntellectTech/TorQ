//- log requests made to DA API

.dataaccess.stats:([]user:();time:();handle:();request:();additionalinfo:());

\d .requests
                          
logenabled:@[value;`.requests.logenabled;1b];                           / if enabled in memory table logs info on requests to API                
additionalinfo:@[value;`.requests.additionalinfo;()!()];                / Dictionary of other (can be process specific) info to track          

logger:{[inputparams;result]
  if[not .requests.logenabled;:()];
  addinfo:.requests.additionalinfo;
  addinfo:$[addinfo~()!();addinfo;@[addinfo;key addinfo;@;enlist inputparams]]; 
  `.dataaccess.stats upsert 
     (.z.u;.z.p;.z.w;inputparams;addinfo);
  };



