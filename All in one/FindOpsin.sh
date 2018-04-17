#!/bin/bash
#---------------------------------------
#searching Assembley information from NCBI
#.......................................
echo "searching for Genome data..."
temp=`esearch -db assembly -query "$1" | efetch -format docsum |xtract -pattern DocumentSummary -unless RefSeq_category -equals na -tab "|" -def "N/A" -element SpeciesName FtpPath_GenBank FtpPath_RefSeq Coverage`
[[ "$temp" = "" ]] && echo "[Warning] no record found, wrong species name?" && exit
sep=`echo $temp | grep -o '|' | wc -l`
[[ $sep > 3 ]]&&echo "[Warning] more than one representative genome records, please specify the query." && exit
#if correct
OIFS=$IFS;IFS='|';set -- $temp; SP=$1;FTP_GB=$2;FTP_RS=$3;Coverage=$4;IFS=$OIF
SP=`echo $SP | sed -e 's/ /_/g'`
echo -e "species: $SP\nFtpPath_GenBank: $FTP_GB\nFtpPath_RefSeq: $FTP_RS\nCoverage: $Coverage"
#---------------------------------------
#Download Genome/Proteome file from FTP site
#.......................................
echo "checking FTP files..."
if [[ "$FTP_GB" = "N/A" ]];then
    GB_Genome=0; GB_Proteome=0
else
    wget -q --no-remove-listing --spider ${FTP_GB}/
    cat .listing > FTP_GB.listing
    grep -q "genomic.fna.gz" FTP_GB.listing && GB_Genome=1 || GB_Genome=0
    grep -q "protein.faa.gz" FTP_GB.listing && GB_Proteome=1 || GB_Proteome=0
fi
if [[ "$FTP_RS" = "N/A" ]];then
    RS_Genome=0; RS_Proteome=0
else
    wget -q --no-remove-listing --spider ${FTP_RS}/ 
    cat .listing > FTP_RS.listing
    grep -q "genomic.fna.gz" FTP_RS.listing && RS_Genome=1 || RS_Genome=0
    grep -q "protein.faa.gz" FTP_RS.listing && RS_Proteome=1 || RS_Proteome=0
fi

echo -e "GenBank: $GB_Genome Genome, $GB_Proteome Proteome\nRefSeq: $RS_Genome Genome, $RS_Proteome Proteome"

if [[ $GB_Proteome = 1 || $RS_Proteome = 1 ]];then
  while :
  do
    read -p "Use Proteome? [Y/N]" confirm
    if [[ "$confirm" = "Y" || "$confirm" = "y" ]];then
	Download_proteome=1
	break
    elif [[ "$confirm" = "N" || "$confirm" = "n" ]];then
	Download_proteome=0
	break
    elif [[ "$confirm" = "Q" || "$confirm" = "q" ]];then
	exit
    fi
  done 
else
    Download_proteome=0
fi

if [[ $Download_proteome = 1 && $RS_Proteome = 1 ]];then
    read "Downloading RefSeq Proteome file. Press any key" -n 1 a
    wget -P $SP ${FTP_RS}/*protein.faa.gz
elif [[ $Download_proteome = 1 && $RS_Proteome = 0 ]];then
    read "Downloading GenBank Proteome file. Press any key" -n 1 a
    wget -P $SP ${FTP_GB}/*protein.faa.gz
elif [[ $Download_proteome = 0 && $RS_Genome = 1 ]];then
    read -p "Downloading RefSeq Genome file. Press any key" -n 1 a
    FILE=`cat FTP_RS.listing | awk '{print$9}'| grep genomic.fna.gz|grep -v _from_ | sed -e 's/\r$//'`
    wget -P $SP ${FTP_RS}/$FILE
else 
    read -p "Downloading GenBank Genome file. Press any key" -n 1 a
    FILE=`cat FTP_GB.listing | awk '{print$9}'| grep genomic.fna.gz|grep -v _from_ | sed -e 's/\r$//'`
    wget -P $SP ${FTP_GB}/$FILE
fi
rm *.listing
#---------------------------------------
#Make blast library 
#.......................................
#unzip
echo "Unzipping..."
gunzip ${SP}/*.gz || exit
#[[ $Download_proteome = 1 ]] && makeblastdb -in *protein.faa -out ${SP}_prot -dbtype prot && mv ${SP}_prot.* $BLASTDB || makeblastdb -in *genomic.fna -out ${SP}_nt -dbtype nucl && mv ${SP}_nt.* $BLASTDB

if [[ $Download_proteome = 0 ]];then
    echo "Making blast nucleotide library..."
    makeblastdb -in ${SP}/*genomic.fna -out ${SP}/${SP}_nt -dbtype nucl
    mv ${SP}/${SP}_nt.* $BLASTDB
#-----------------------------------
#tblastn
#...................................
    echo "tblastn..."
    tblastn -db ${SP}_nt -query probe.fas -out ${SP}/${SP}.tblastn.out  -evalue 1e-10 -outfmt "7 qacc sacc sseqid evalue qcovs pident score bitscore sstart send qstart qend"
    echo "Summarzing..."
    sed -r '/^#/d' ${SP}/${SP}.tblastn.out | sort -k2,2 -k9n,9  > ${SP}/${SP}.tblastn.sort
    ./summary.sh $SP 
#-----------------------------------------
#Efetch sequences from NCBI
#........................................
    echo "Efetch sequences from NCBI"
    ./efetch.sh $SP
    read -p "OK?" a
#--------------------------------------
#Running Augustus
#...............................
    echo "Running Augustus"
    augustus --species=heliconius_melpomene1 --proteinprofile=protein_profile.prf1 --outfile=${SP}/${SP}.augustus --gff3=on ${SP}/${SP}.efetch
#-----------------------------------------------
#Get protein sequences from Augustus output file
#................................................
    echo "Get protein sequences from Augustus output file"
    ./getprot.sh $SP
#-----------------------------------------------
#Make blast protein library
#................................................
    echo "Make blast protein library"
    makeblastdb -in ${SP}/${SP}.augustus.prot.fas -out ${SP}/${SP}_prot -dbtype prot
else
    makeblastdb -in ${SP}/*protein.faa -out ${SP}/${SP}_prot -dbtype prot
fi
mv ${SP}/${SP}_prot.* $BLASTDB

echo  "blastp..."
blastp -db ${SP}_prot -query probe.fas -out ${SP}/${SP}.blastp.out  -evalue 1e-20 -outfmt "7 qacc sacc sseqid evalue qcovs pident score bitscore sstart send qstart qend"

echo "summarizing..."
sed -r '/^#/d' ${SP}/${SP}.blastp.out | awk '{print $2}' | sort -n | uniq > ${SP}/${SP}.blastp.sort
#---------------------------
#Get fasta sequence
#...........................
if [[ $Download_proteome = 0 ]];then
    [[ -f "${SP}/${SP}.opsin.fas" ]] && rm ${SP}/${SP}.opsin.fas
    while read line || [[ -n $line ]];do
        cat ${SP}/${SP}.augustus |grep 'transcript'|grep "g$line.t"|awk '{print ">g'$line'_" $1 ":" $4 "-" $5}' >> ${SP}/${SP}.opsin.fas
        upperline=`sed  -n  "/>${line}$/=" ${SP}/${SP}.augustus.prot.fas`
        upperline=$(($upperline+1))
        line=$(($line+1))
        lowerline=`sed  -n  "/>${line}$/=" ${SP}/${SP}.augustus.prot.fas`
        if [ -z "$lowerline" ];then
            lowerline=`sed -n '$=' ${SP}/${SP}.augustus.prot.fas`
        else
            lowerline=$(($lowerline-1))
        fi
        sed -n "${upperline},${lowerline}p" ${SP}/${SP}.augustus.prot.fas>>${SP}/${SP}.opsin.fas
    done < ${SP}/${SP}.blastp.sort
#------------------
#split fasta file
#..................
    perl fasta-splitter.pl --part-size 2000 --out-dir ${SP} ${SP}/${SP}.opsin.fas
fi
