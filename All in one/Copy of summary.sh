#!/bin/bash
SP=$1
flanking=10000
FILE=${SP}/${SP}.tblastn.sort
csseq="null"
csstart=0
csend=0
cqstart=0
cqend=0
cstrand='+'
cnum=0
while read line || [[ -n $line ]];do
    sseq=`echo \'$line\' | awk  '{print $2}'`
  sstart=`echo \'$line\' | awk '{print $9}'`
    send=`echo \'$line\' | awk '{print $10}'`
  qstart=`echo \'$line\' | awk '{print $11}'`
    qend=`echo \'$line \' | awk '{print $12}'`
    if [ $sstart -lt $send ];then
	strand='+'
	gap=$(($sstart-$csend))
    else
	strand='-'
	gap=$(($send-$csstart))
    fi
    if [ "$csseq" = "$sseq" -a $gap -lt $flanking -a $gap -gt -$flanking ]; then
	cnum=$((cnum+1))
	if [ $qstart -lt $cqstart ]; then
            cqstart=$qstart
        fi
        if [ $qsend -gt $cqsend ];then
            cqsend=$qsend
        fi
	if [ $cstrand = '+' ]; then
	    if [ $sstart -lt $csstart ];then
		csstart=$sstart
	    fi
	    if [ $ssend -gt $cssend ];then
		cssend=$ssend
	    fi
	elif [ $cstrand = '-' -a $sstart -gt $csstart ];then
	    if [ $sstart -gt $csstart ];then
                csstart=$sstart
            fi
            if [ $ssend -lt $cssend ];then
                cssend=$ssend
            fi
	fi
    else
	echo -e "$csseq\t$csstart\t$csend\t$cstrand\t$cqstart\t$cqend\t$cnum" >> ${SP}/${SP}.tblastn.summary
	csseq=$sseq
	csstart=$sstart
	csend=$send
	cqstart=$qstart
	cqend=$qend
	cstrand=$strand
	cnum=1
    fi
done < $FILE
echo -e "$csseq\t$csstart\t$csend\t$cstrand\t$cqstart\t$cqend\t$cnum" >> ${SP}/${SP}.tblastn.summary
sed -i '1d' ${SP}/${SP}.tblastn.summary
