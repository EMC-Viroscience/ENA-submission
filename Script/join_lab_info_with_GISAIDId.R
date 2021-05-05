library(dplyr)

# Obtain directly from GISAID website
GISAID_retrieve <- read.delim("GISAID_retrieve.tsv")
GISAID_needed <- GISAID_retrieve[,c(1,3,5,8)]
# Obtained fron spreadsheet of lab, with only the following column (must be kept in the same order): Datum afname, Sequence datum,	Sequence run,	Sequence Barcode,	Sequence name GISAID,	Sequence name GISAID corrected	
sample_all <- read.delim("list_all_sample_main_spreadsheet_NL_nanopore.txt")
names(GISAID_needed) <- c("seq_id","GID","date","region")
names(sample_all)[6] <- c("seq_id")


join_info <- inner_join(GISAID_needed, sample_all[,c(3,4,6)], by="seq_id")
ordered <- join_info[order(join_info$Sequence.run),]

write.csv(ordered,'sample_metadata.csv')
