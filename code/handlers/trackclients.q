// taken from http://code.kx.com/wsvn/code/contrib/simon/dotz/
/ track active clients of a kdb+ session in session table CLIENTS
/ when INSTRUSIVE is true .z.po goes back asking for more background
/ use monitorusage.q or logusage.q if you need request by request info
/ port - port at po time, _may_ have been changed by a subsequent \p
/ sz - total (uncompressed) bytes transferred, could use it to bounce greedy clients
/ startp - when the session started (.z.po)
/ endp - when the session ended (.z.pc)
/ lastp - time of last session activity (.z.pg/ps/ws)

\d .clients

enabled:@[value;`enabled;1b]            	// whether this code is automatically enabled
opencloseonly:@[value;`opencloseonly;0b] 	// whether we only log opening and closing of connections

// Create a clients table
clients:@[value;`clients;([w:`int$()]ipa:`symbol$();u:`symbol$();a:`int$();k:`date$();K:`float$();c:`int$();s:`int$();o:`symbol$();f:`symbol$();pid:`int$();port:`int$();startp:`timestamp$();endp:`timestamp$();lastp:`timestamp$();hits:`int$();errs:`int$();sz:`long$())]

unregistered:{except[key .z.W;exec w from`CLIENTS]} / .clients.addw each unregistered[]
cleanup:{ / cleanup closed or idle entries
    if[count w0:exec w from`.clients.clients where not .dotz.livehn w;
        update endp:.proc.cp[],w:0Ni from`.clients.clients where w in w0];
    if[.clients.MAXIDLE>0;
        hclose each exec w from`.clients.clients where .dotz.liveh w,lastp<.proc.cp[]-.clients.MAXIDLE];
    delete from`.clients.clients where not .dotz.liveh w,endp<.proc.cp[]-.clients.RETAIN;}
hit:{update lastp:.proc.cp[],hits:hits+1i,sz:sz+-22!x from`.clients.clients where w=.z.w;x}
hite:{update lastp:.proc.cp[],hits:hits+1i,errs:errs+1i from`.clients.clients where w=.z.w;'x}
po:{[result;W]
    cleanup[];
    `.clients.clients upsert(W;.dotz.ipa .z.a;.z.u;.z.a;0Nd;0n;0Ni;0Ni;(`);(`);0Ni;0Ni;zp;0Np;zp:.proc.cp[];0i;0i;0j);
    if[INTRUSIVE;
        neg[W]"neg[.z.w]\"update k:\",(string .z.k),\",K:\",(-3!.z.K),\",c:\",(-3!.z.c),\",s:\",(-3!system\"s\"),\",o:\",(-3!.z.o),\",f:\",(-3!.z.f),\",pid:\",(-3!.z.i),\",port:\",(-3!system\"p\"),\" from`.clients.clients where w=.z.w\""];
    result}
addw:{po[x;x]} / manually add a client
pc:{[result;W] update w:0Ni,endp:.proc.cp[] from`.clients.clients where w=W;cleanup[];result}

.z.pc:{.clients.pc[x y;y]}.z.pc;

wo:{[result;W]
    cleanup[];
    `.clients.clients upsert(W;.dotz.ipa .z.a;.z.u;.z.a;0Nd;0n;0Ni;0Ni;(`);(`);0Ni;0Ni;zp;0Np;zp:.proc.cp[];0i;0i;0j);
    result}

if[enabled;
	.z.po:{.clients.po[x y;y]}.z.po;
        .z.wo:{.clients.wo[x y;y]}.z.wo;
	.z.wc:{.clients.pc[x y;y]}.z.wc;

	if[not opencloseonly;
		.z.pg:{.clients.hit[@[x;y;.clients.hite]]}.z.pg;
		.z.ps:{.clients.hit[@[x;y;.clients.hite]]}.z.ps;
		.z.ws:{.clients.hit[@[x;y;.clients.hite]]}.z.ws;]];

/ if no other timer then go fishing for zombie clients every .clients.MAXIDLE
/ if[not system"t";
/    .z.ts:{.clients.cleanup[]};
/    system"t ",string floor 1e-6*.clients.MAXIDLE]
