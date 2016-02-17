\d .config

getConfigDef:{[path;both;rev]
        /-check if KDBAPPCONFIG exists
        keyappconf:$[count kac:getenv[`KDBAPPCONFIG];
                key hsym appconf:`$kac,"/",path;
                ()];

	appconfigfile:not ()~keyappconf;

        /-get KDBCONFIG path
        keyconf:key hsym conf:`$(kc:getenv[`KDBCONFIG]),"/",path;

        /-if path is an existing directory then append filenames to path
        if[appconfigfile;
                if[(not count ss[string first keyappconf;kac]);
                        keyappconf:appconf:` sv' appconf,/:keyappconf]];

        /-if path is an existing directory then append filenames to path
        if[not ()~keyconf;
                if[(not count ss[string first keyconf;kc]);
                        conf:` sv' conf,/:keyconf]];

        /-if both is set to true return appconfig and config files
        /-result is reversed if rev is true
        res:$[both & appconfigfile;
                $[rev;  
                        conf,appconf;
                        appconf,conf];
                $[count keyappconf;
                        appconf;
                        conf]];

	/-if only one result then return an atom
	$[1=count res;first res;res]}

getConfig:getConfigDef[;;0b]

getConfigFile:getConfigDef[;0b;0b]
