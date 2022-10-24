# Perl parser for ENA submission

This parser was made specifically for the addition of new sample to the Study PRJEB39014 present on ENA.

## Required file and arguments 

The parser take three argument 

 - csv file containing information about the samples
 - md5 file containing the md5sum value
 - directory in which the xml file must be store
 
 The csv file must have the following format : 
 
| # |   seq_id                               |   GID          |   date        |   region  |   Sequence.run          |   Sequence.Barcode  |
|---|----------------------------------------|----------------|---------------|-----------|-------------------------|---------------------|
| 1 |   hCoV-19/Netherlands/xy-ZZZ-1001/2020 | EPI_ISL_xyyxzz |   15/05/2020  | anywhere  |   GRIDIon_Viro_Run_XXX  | BCXX                |
| 2 |   hCoV-19/Netherlands/xy-ZZZ-1002/2020 | EPI_ISL_xyyxzz |   17/05/2020  | anywhere  |   GRIDIon_Viro_Run_XXX  | BCXX                |
| 3 |   hCoV-19/Netherlands/xy-ZZZ-1003/2020 | EPI_ISL_xyyxzz |   18/05/2020  | anywhere  |   GRIDIon_Viro_Run_XXX  | BCXX                |
| 4 |   hCoV-19/Netherlands/xy-ZZZ-1004/2020 | EPI_ISL_xyyxzz |   09/05/2020  | anywhere  |   GRIDIon_Viro_Run_X    | BCXX                |
|   |                                        |                |               |           |                         |                     |
|   |                                        |                |               |           |                         |                     |

And can be obtained using the R script present in this repository ( join_lab_info_with_GISAIDId.R , the # must be manually added to the file )

The md5 file as the format: 

```
829fe2933c91a9dfd21a2f6829323050  RunXXX_BCXX.fastq.gz  
edad51d035047bee35858e48ef7eff57  RunXXX_BCXX.fastq.gz  
c0bcfe4426d4d2e66b0870d945a72ecc  RunXXX_BCXX.fastq.gz  
a375855f5c82049be582f0aa31ee0e1f  RunXXX_BCXX.fastq.gz  
a620a2c300e5183f3687520cd21c46d3  RunXXX_BCXX.fastq.gz  
```

This file can be obtain by running the following command in the directory containing the .fastq.gz files 

```bash
for i in *.fastq; do pigz -c $i > gzip/$i.gz; done;
md5sum * > checklist.chk
```

## Usage 

```bash
perl produce_xml_ProgranRoutes.pl sample.csv checklist.chk /Users/ENA-submission/xml-file/
```
