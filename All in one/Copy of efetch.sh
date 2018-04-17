#!/bin/bash
SP=$1
while read line || [[ -n $line ]];do
seqid=`echo $line | awk '{print $1}'`
strand=`echo $line | awk '{print $4}'`
if [ $strand = '+' ];then
    seqstart=`echo $line | awk '{print $2}'`
    seqstop=`echo $line | awk '{print $3}'`
else
    seqstart=`echo $line | awk '{print $3}'`
    seqstop=`echo $line | awk '{print $2}'`
fi
seqstart=$(($seqstart-5000))
seqstop=$(($seqstop+5000))
efetch -db nuccore -id $seqid -seq_start $seqstart -seq_stop $seqstop -format fasta >> ${SP}/${SP}.efetch
done < ${SP}/${SP}.tblastn.summary
