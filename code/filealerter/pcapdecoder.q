// Decoder is designed for pcap version 2.4
// Info on pcap structure => https://www.kroosec.com/2012/10/a-look-at-pcap-file-format.html

\d .pcap

// size of headers in bytes and dict of protocol code conversions
globheader: 24;
packetheader: 16;

// mapping from protocol id numbers to protocol name
// add desired protocols to dictionary for decoder to be able to translate their id's
allcodes:(enlist 6)!(enlist `TCP);


// returns table of packet data
buildtable:{[file]
 // check that version number of input file is 2.4, if incorrect function exits
 pcapversioncheck: all 2 0 4 0 = read1(file;4;4);
 if[not pcapversioncheck;.lg.o[`alerter;"pcap version number of ",(1_string file), " is incorrect, so could not be decoded"];:()];

 // if version is correct, gettablerow is iterated over each datapacket, extracting data
 data:1_ last each {[filebinary] // initial x and binary starting numbers removed from array list to make table
  filebytesize: count filebinary;
  // x here is a list containing starting binary point for packet (x[0]), the most recent win scaling factor (x[1]) and row of data for that packet (x[1])
  gettablerow[filebinary;]\[{y>(first x[0])+40}[;filebytesize];(),0,1]
  } read1 file;
 
 data: update sym:` from data;
 `time`sym xcols data
 }


// returns starting point of next packet and row data
gettablerow:{[filebinary;x]  // data for a single row
 // x is a list containing starting binary point for packet (x[0]), the most recent win scaling factor (x[1]) and row of data for that packet (x[2])
 time:           gettime[filebinary;x];
 protocol:       getprotocol[filebinary;x];
 ips:            getips[filebinary;x];
 flags:          getflags[filebinary;x];
 winscalefactor: $[`SYN in flags;"i"$ 2 xexp filebinary[globheader+packetheader+x[0]+75];x[1]];
 info:           getinfo[filebinary;x;flags;winscalefactor];
 
 totallength: 0x0 sv datafromfile[filebinary;x;18;2];
 IPheader:    4*"J"$last string filebinary[x[0]+globheader+packetheader+16];
 TCPheader:   4* first "0123456789abcdef"?/:string filebinary[x[0]+globheader+packetheader+48];
 len:         (first first totallength - IPheader + TCPheader) mod 65536;

 length: (0x0 sv reverse filebinary[x[0]+36 37]) mod 65536;
 data:   datafromfile[filebinary;x;length - len;len];

 // array containing starting point for next byte and dictionary of data for current packet
 (x[0] + length + 16;winscalefactor;`time xcols ips,info,`time`flags`length`len`data!(time;flags;length;len;data))
 }


gettime:{[filebinary;x]
 first linuxtokdbtime ("iiii";4 4 4 4)1: packetheader#(globheader+x[0]) _ filebinary
 }

linuxtokdbtime:{[time]
 // converts time in global header to nanoseconds then accounts for difference in epoch dates in kdb and linux
 // time[0] is in seconds, time[1] is microseconds offset to time[0]
 "p"$1000*time[1]+1000000*time[0]-10957*86400
 }

datafromfile:{[filebinary;x;start;numofbytes]
 numofbytes#(globheader+packetheader+x[0]+start) _ filebinary
 }

getflags:{[filebinary;x]
 // flag data stored at 49th byte
 bools: 2 vs filebinary[globheader+packetheader+x[0]+49];
 `CWR`ECE`URG`ACK`PSH`RST`SYN`FIN where ((8 - count bools)#0), bools
 }

getprotocol:{[filebinary;x]
 // code number is stored at 25th byte of packet
 code: "i"$filebinary[globheader+packetheader+x[0]+25];
 protocol: $[code in key allcodes; allcodes[code]; code] 
 }

getinfo:{[filebinary;x;flags;windowscale]
 // grabs multiple sets of data starting at 36th byte
 elements: first each ((2 2 4 4 2 2 8 4 4;"hhii h ii")1: datafromfile[filebinary;x;36;32]);
 
 // elements must be less than the max of their respective types, so mod needs to be applied
 elements[0 1 4]:   elements[0 1 4] mod 65536;        // 65536 = max. of unsigned short - 1
 elements[2 3 5 6]: elements[2 3 5 6] mod 4294967296; // 4294967296 = max of unsigned integer - 1
 
 //multiplies window by window scaling from most recent SYN packet
 if[not `SYN in flags;elements[4]:elements[4] * windowscale];
 `srcport`destport`seq`ack`win`tsval`tsecr!elements
 }

getips:{[filebinary;x]
 // ip data starts at 28th byte
 elements: `$"." sv ' string 4 cut "i"$datafromfile[filebinary;x;28;8];
 `src`dest!elements
 } 
