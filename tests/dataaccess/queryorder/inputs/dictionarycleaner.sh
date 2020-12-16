sed -i -z 's/tablename/parameter,parametervalue\ntablename/g' $1

sed -i -z 's/,/enlist /g' $1

sed -i -z 's/| /,/g' $1

cat $1
