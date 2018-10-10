# FindOpsin
Find Opsin CDS from (Lepidoptera) Genome or Proteome
## Prerequisite environment & files:
### Environment:
Blastx: https://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download
Augustus: http://bioinf.uni-greifswald.de/augustus/binaries/
Edirect: https://dataguide.nlm.nih.gov/edirect/install.html
BioPerl: http://bioperl.org/INSTALL.html
### Files:
probe.fas: the file contains all kinds of opsin protein sequences, including 5 LW, 7 B, 7 UV, 6 Rh7, 6 Copsin, 6 GO/RGR opsins. Used for blastp against Proteome or tblastn against Genome.
protein_profile.prf1: the file contains protein profile for opsin. Generated from alignment of probe.fas, using ‘msa2prfl.pl probe.aln > fam.prfl’. Used for gene predicting when running Augustus.
fasta-splitter.pl: split large fasta file to multiple small fasta files for online blast.

## Workflow:
### Proteome:
Download Proteome data from “NCBI Assembly” or “Ensemble” (using Edirect).
Make protein blast library.
Blastp probe.fas against the library (evalue=1e-20)
Extract seqid of potential opsin sequences from blastp output files.
Blast potential opsin sequences against online database, exclude incorrect sequences or pseudogenes.
Align new-found opsin sequences together with opsin sequences in probe.fas, construct a tree.
Determine number and type of new-found opsin genes.
### Genome:
Download Genome data from “NCBI Assembly” or “Ensemble” (using Edirect).
Make nucleotide blast library.
tblastn probe.fas against the library.
Extract information from tblastn output files, including seqid, start and end position of matching part of subject sequence (usually the subject sequences are assembled scaffolds or contigs, which is very long)
Efetch the partial sequences base on the information (expanding the original matching range to 10000 bp upstream and 10000 bp downstream in order to include the complete gene) from NCBI
Run Augustus with input of protein profile (protein_profile.prf1) against the fetched partial genomic file to predict proteins.
Extract predicted protein sequences form Augustus output file.
Make protein blast library using predicted protein sequences.
Blastp probe.fas against the library (evalue=1e-20)
Extract seqid of potential opsin sequences from blastp output files.
Blast potential opsin sequences against online database, exclude incorrect sequences or pseudogenes.
Align new-found opsin sequences together with opsin sequences in probe.fas, construct a tree.
Determine number and type of new-found opsin genes.

## Problems still need to address:
Hard to tell whether the new-found opsin sequences are actual real genes or pseudogenes.
Might get partial opsin sequences, 3 possibilities: 1) Augustus failed to predict upstream or downstream exon. 2) The sequencing quality is not so good that a gap appears at the range of the opsin gene. 3) That is debris of opsin that had lost the function early in evolution. How to tell?
