/-Defines the default variables for the file alerter process


\d .fa

inputcsv:first .proc.getconfigfile["filealerter.csv"]			// The name of the input csv to drive what gets done
polltime:0D00:00:10						// The period to poll the file system	
alreadyprocessed:first .proc.getconfigfile["filealerterprocessed"]	// The location of the table on disk to store the information about files which have already been processed
skipallonstart:0b						// Whether to skip all actions when the file alerter process starts up (so only "new" files after the processes starts will be processed)
moveonfail:0b							// If the processing of a file fails (by any action) then whether to move it or not regardless
