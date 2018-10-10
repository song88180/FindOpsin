# FindOpsin
Find Opsin CDS from (Lepidoptera) Genome or Proteome
## Prerequisite environment & files:
### Environment:
Blastx: https://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download <br>
Augustus: http://bioinf.uni-greifswald.de/augustus/binaries/ <br>
Edirect: https://dataguide.nlm.nih.gov/edirect/install.html <br>
BioPerl: http://bioperl.org/INSTALL.html <br>
### Files:
probe.fas: the file contains all kinds of opsin protein sequences, including 5 LW, 7 B, 7 UV, 6 Rh7, 6 Copsin, 6 GO/RGR opsins. Used for blastp against Proteome or tblastn against Genome. <br>
protein_profile.prf1: the file contains protein profile for opsin. Generated from alignment of probe.fas, using ‘msa2prfl.pl probe.aln > fam.prfl’. Used for gene predicting when running Augustus. <br>
fasta-splitter.pl: split large fasta file to multiple small fasta files for online blast. <br>

## Workflow:
### Proteome:
Download Proteome data from “NCBI Assembly” or “Ensemble” (using Edirect). <br>
Make protein blast library. <br>
Blastp probe.fas against the library (evalue=1e-20) <br>
Extract seqid of potential opsin sequences from blastp output files. <br>
Blast potential opsin sequences against online database, exclude incorrect sequences or pseudogenes. <br>
Align new-found opsin sequences together with opsin sequences in probe.fas, construct a tree. <br>
Determine number and type of new-found opsin genes. <br>
### Genome:
Download Genome data from “NCBI Assembly” or “Ensemble” (using Edirect). <br>
Make nucleotide blast library. <br>
tblastn probe.fas against the library. <br>
Extract information from tblastn output files, including seqid, start and end position of matching part of subject sequence (usually the subject sequences are assembled scaffolds or contigs, which is very long) <br>
Efetch the partial sequences base on the information (expanding the original matching range to 10000 bp upstream and 10000 bp downstream in order to include the complete gene) from NCBI <br>
Run Augustus with input of protein profile (protein_profile.prf1) against the fetched partial genomic file to predict proteins. <br>
Extract predicted protein sequences form Augustus output file. <br>
Make protein blast library using predicted protein sequences. <br>
Blastp probe.fas against the library (evalue=1e-20) <br>
Extract seqid of potential opsin sequences from blastp output files. <br>
Blast potential opsin sequences against online database, exclude incorrect sequences or pseudogenes. <br>
Align new-found opsin sequences together with opsin sequences in probe.fas, construct a tree. <br>
Determine number and type of new-found opsin genes. <br>

## Problems still need to be addressed:
Hard to tell whether the new-found opsin sequences are actual real genes or pseudogenes. <br>
Might get partial opsin sequences, 3 possibilities: 1) Augustus failed to predict upstream or downstream exon. 2) The sequencing quality is not so good that a gap appears at the range of the opsin gene. 3) That is debris of opsin that had lost the function early in evolution. How to tell?
