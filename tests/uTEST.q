def: .Q.def[`stackID`user`pass`testCSV`benchM!(1680;`admin;`admin;`:UnitTesting/tests.csv;`:UnitTesting/benchM/)].Q.opt[.z.x]; 
path:`$"::",string[def[`stackID]],":",string[def[`user]],":",string[def[`pass]];

//load files
\l k4unit.q

benchCheck:{$[`quoteBENCHMARK.csv in key def[`benchM];
              $[`tradeBENCHMARK.csv in key def[`benchM];
                $[`tablerBENCHMARK.csv in key def[`benchM];
                 [0];
                 -1"tablerBENCHMARK.csv MISSING"];
              -1"tradeBENCHMARK.csv MISSING"];
            -1"BENCHMARKS MISSING"]};

$[0<>benchCheck[];system"l createBENCHMARK.q";-1"BENCHMARKS AVAILABLE..."];

selColType:{[table;typ]
             //pass table and type as string i.e. "i" for integer or "s" for symbol
             raze exec c from (key meta table) where typ=(flip 0!meta table)[`t]
           };

tMan:{[table;typ]
        //checks which columns are float and converts them to ints for comparison.
        ![table;();0b;((),selColType[table;typ])!({[x]`int$100*x }),/:selColType[table;typ]]
     };

lCSV:{[path]
       //loads the benchmark tables which come in csv format
       quoteBENCHMARK::("PSFF";enlist ",")0: hsym`$string[path],"quoteBENCHMARK.csv"; 
       tradeBENCHMARK::("SIJ";enlist ",")0: hsym`$string[path],"tradeBENCHMARK.csv";
       tablerBENCHMARK::("SIJFF";enlist ",")0: hsym`$string[path],"tablerBENCHMARK.csv";
       {tMan[x;"f"]}'[`quoteBENCHMARK`tradeBENCHMARK`tablerBENCHMARK];
     };

loadBench:{
            $[0=benchCheck[];
            [lCSV[def[`benchM]];-1"BENCHMARKS LOADED..."];]
          };
 
opHandle:{@[hopen;path;{-2"ERROR: ",x}]}; /- open handle to eodsum.q  

 /- checks if the test are .csv or dir and invokes a different function in k4unit to load them up
loadTest:{$[not "csv"~-3#string[def[`testCSV]];KUltd def[`testCSV];KUltf def[`testCSV]]};

init:{
      loadBench[]; 
      h::opHandle[]; /- opening handle to process  
      loadTest[];   /- load CSVs containing the tests 
      KUrt[];     /- run tests 
     }

init 0 

 




