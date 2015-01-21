# if running the kdb+tick example, change these to full paths
# some of the kdb+tick processes will change directory, and these will no longer be valid
export KDBCONFIG=${PWD}/config
export KDBCODE=${PWD}/code
export KDBLOG=${PWD}/logs
export KDBHTML=${PWD}/html
export KDBLIB=${PWD}/lib

# if using the email facility, modify the library path for the email lib depending on OS
# e.g. linux:
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l[32|64]
# e.g. osx:
# export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$KDBLIB/m[32|64]
