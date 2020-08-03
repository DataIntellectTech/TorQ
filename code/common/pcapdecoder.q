\d .pcap

// size of headers in bytes and dict of protocol code conversions
globheader: 24;
packetheader: 16;
allcodes:(enlist 6)!(enlist `TCP);


buildtable:{[file]
 // initial x and byte cut points removed from array list to make table
 // gettablerow is iterated over each datapacket, extracting data

 data:1_ last each {[n]
  filebytesize: count n;
  gettablerow[n;]\[{y>(first x[0])+40}[;filebytesize];(),0]    
  } read1 file;
 
 data: update No:i+1 from data;
 `No xcols data
 }


gettablerow:{[n;x]  // data for a single row
 time:     gettime[n;x];
 flags:    getflags[n;x];
 protocol: getprotocol[n;x];
 
 totallength: (enlist 2;enlist "h")1: datafromfile[n;x;18;2];
 IPheader:    4*"J"$last string n[x[0]+globheader+packetheader+16];
 TCPheader:   4* first "0123456789abcdef"?/:string n[x[0]+globheader+packetheader+48];
 len:         (first first totallength - IPheader + TCPheader) mod 65536;

 length: first raze ((enlist "h";enlist 2)1: n[x[0]+36 37]) mod 65536;
 data:   datafromfile[n;x;length - len;len];

 ips: getips[n;x]; 
 src:  ips[0];
 dest: ips[1];

 info: getinfo[n;x];
 srcport:  info[0] mod 65536;
 destport: info[1] mod 65536;
 seq:      info[2] mod 4294967296;
 ack:      info[3] mod 4294967296;
 win:      info[4] mod 65536;
 tsval:    info[5] mod 4294967296;
 tsecr:    info[6] mod 4294967296;

 // array containing starting point for next byte and dictionary of data for current packet
 (x[0] + length + 16;`time`src`dest`srcport`destport`protocol`flags`seq`ack`win`tsval`tsecr`length`len`data!(time;src;dest;srcport;destport;protocol;flags;seq;ack;win;tsval;tsecr;length;len;data))
 }


gettime:{[n;x]
 linuxtokdbtime ("iiii";4 4 4 4)1: packetheader#(globheader+x[0]) _ n
 }

linuxtokdbtime:{
 // converts time in global header to nanoseconds then accounts for difference in epoch dates in kdb and linux
 "p"$1000*x[1]+1000000*x[0]-10957*86400
 }

datafromfile:{[n;x;start;numofbytes]
 numofbytes#(globheader+packetheader+x[0]+start) _ n
 }

getflags:{[n;x]
 // flag data stored at 49th byte
 bools: 2 vs n[globheader+packetheader+x[0]+49];
 `CWR`ECE`URG`ACK`PSH`RST`SYN`FIN where ((8 - count bools)#0), bools
 }

getprotocol:{[n;x]
 // code number is stored at 25th byte of packet
 code: "i"$n[globheader+packetheader+x[0]+25];
 protocol: $[code in key allcodes; allcodes[code]; code] 
 }

getinfo:{[n;x]
 // grabs multiple sets of data starting at 36th byte
 ((2 2 4 4 2 2 8 4 4;"hhii h ii")1: datafromfile[n;x;36;32])
 }

getips:{[n;x]
 // ip data starts at 28th byte
 `$"." sv ' string 4 cut "i"$datafromfile[n;x;28;8]
 } 
