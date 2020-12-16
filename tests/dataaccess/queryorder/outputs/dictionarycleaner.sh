sed -i -z 's/0|/parameter,parametervalue\n0|/g' $1

sed -i -z 's/,/enlist /g' $1

sed -i -z 's/| /,/g' $1

cat $1
