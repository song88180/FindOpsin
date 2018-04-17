#/bin/bash
SP=$1
FILE=${SP}/${SP}.augustus
flag=0
num=0
while read line || [[ -n $line ]];do
  if [[ $line =~ "protein sequence" ]] ;then
    flag=1
    num=$(($num+1))
    echo $line | sed -e "s/protein sequence = \[/>$num\n/" >> ${FILE}.prot.fas
  elif [[ $flag == 1 ]];then
    echo $line >> ${FILE}.prot.fas
  fi
  if [[ $line =~ "]" ]] ;then
    flag=0
  fi
done < $FILE
sed -i 's/# //' ${FILE}.prot.fas 
sed -i 's/]//' ${FILE}.prot.fas
