\d .dataaccess

tablepropertiespath:first .proc.getconfigfile["tableproperties.csv"];       	// config defining any non standard attribute/primary time columns
dataaccessparamspath:first .proc.getconfigfile["dataaccessparams.csv"];	      	// The name of the input csv to drive what gets done

\d .proc

loadprocesscode:1b;                    						// Whether to load the process specific code defined at ${KDBCODE}/{process type}
