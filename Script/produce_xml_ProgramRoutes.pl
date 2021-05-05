#!/usr/bin/env perl

use Modern::Perl '2011';

use autodie;
use Smart::Comments '####';
use Tie::IxHash;
use Time::Piece;
use List::MoreUtils qw(uniq);
use utf8;
use DBI;

use warnings 'FATAL' => 'all'; #used to debug

unless (@ARGV == 3) {
  die << "EOT";
Usage: $0 <csv_file> <md5file> <directory>
This program parse the information present in the csv file and the md5 file into the three xml file: sample.xml, experiment.xml and run.xml for the ENA submission. You also need to provide a directory in which the xml files will be stored.
Example: perl $0 sample.csv checklist.chk /Users/ENA-submission/xml-file/
EOT
}


my $csv_file = shift;
my $md5_file = shift;
my $directory = shift; 
my $sample_xml = $directory . "sample.xml";
my $exp_xml = $directory . "experiment.xml";
my $run_xml = $directory . "run.xml";

### Main script ###

# Extraction of the information fron both the csv file and the md5 file
my $sample_data = extract_data($csv_file);
my $md5_info = extract_data_md5($md5_file);

# Creation of the 3 xml files
fill_xml_sample($sample_data[0], $sample_data[1], $sample_xml);
fill_xml_exp($sample_data[0], $exp_xml);
fill_xml_run($sample_data[0], $md5_info, $run_xml);


### Function ###

## Extraction of data from csv
sub extract_data{
  my $infile = shift;
  my @infos;
  my %data;
  my @column_name;
  my $size;
  my $number;

  ## Opening and reading of the infile
  open my $file, '<', $infile;

	LINE:
	while (my $line = <$file>) {
		chomp $line;
	$line =~ tr/\"//d;
    
    # The next if/else are to first retrieve the column name of the csv and then to extract the information from the csv
    if ($line =~ m/\A \#/xms){
		@column_name = split( /\,/, $line, -1);
		$size = @column_name;
        next LINE;
    }
    else {
      @infos = split( /\,/, $line, -1); # -1 to allow that empty spot at the end of the array are conserved
		
	  # Extract run information depending on the format it was written on the lab spreadsheet
      if ($infos[5] =~ m/GRIDIon_Viro_Run_\d{3}/xms) {
		  $infos[5] =~ s/GRIDIon_Viro_(Run_\d{3})/$1/;
		  $infos[5] =~ tr/_//d;
	  }
	  if ($infos[5] =~ m/Viro_Run_\d{3}/xms) {
		  $infos[5] =~ s/Viro_(Run_\d{3})/$1/;
		  $infos[5] =~ tr/_//d;		  
	  }
	  if ($infos[5] =~ m/Viro_run_\d{3}/xms) {
		  $infos[5] =~ s/Viro_(Run_\d{3})/$1/;
		  $infos[5] =~ tr/_//d;
	  }
	  #Some barcode were missing the 0 (1 instead of 01) so this if is there to correct that
	  if (length($infos[6]) < 4) {
		  my ($bc) = ($infos[6] =~ /BC(\d{1})/);
		  $infos[6] = "BC0" . $bc; 
	  }
      my $ref = $infos[5] . '_' . $infos[6];
      # creation of an hash of hashes to stock all the data extracted
      for my $i (0..$size-1) {
        $data{$ref}{$column_name[$i]} = $infos[$i];
      }
      
    }
  }
  for my $it (keys %data){
	  
      if ($data{$it}{date} =~ m/\d{2}\/\d{2}\/\d{4}/xms){
		  $data{$it}{date} =~ s/(\d{2})\/(\d{2})\/(\d{4})/$3-$2-$1/;
	  }
	  # needed to add information for the sample without region
	  if (length($data{$it}{region})<2){
		  $data{$it}{region} = "not collected";
	  }
  }
 
  return \%data, \@unique_run;
}

#get md5 result for the file
sub extract_data_md5{
  my $infile = shift;
  my @infos;
  my %data;
  ## Opening and reading of the infile
  open my $file, '<', $infile;

	LINE:
	while (my $line = <$file>) {
		chomp $line;    
		  @infos = split( /  /, $line, -1); # -1 to allow that empty spot at the end of the array are conserved
		  my $ref = $infos[1];
		  # creation of an hash of hashes to stock all the data extracted
		  $data{$ref} = $infos[0];
    }
  return \%data;
}

## creation of new xml
sub fill_xml_sample {
  my $data = shift;
  my $run = shift;
  my $outfile = shift;
  my %deref_data = %$data;
  my @deref_run = @$run;
  my $ref;
  
  

  open my $out, '>', $outfile;
  print {$out} '<?xml version="1.0" encoding="UTF-8"?>' . "\n" ;
  my $all_sample; 
  for $ref (keys %deref_data) {
	  
	  $all_sample .= <<"EOF";
	  <SAMPLE alias="$ref" center_name="Dutch COVID-19 response team">
		<TITLE>Dutch COVID-19 response sample sequencing</TITLE>
		<SAMPLE_NAME>
			<TAXON_ID>2697049</TAXON_ID>
			<SCIENTIFIC_NAME>Severe acute respiratory syndrome coronavirus 2</SCIENTIFIC_NAME>
			<COMMON_NAME>Human coronavirus 2019</COMMON_NAME>
		</SAMPLE_NAME>
		<DESCRIPTION>A SARS-CoV-2 specific multiplex PCR for Nanopore sequencing was performed, similar to amplicon-based approaches as previously described. In short, primers for 86 overlapping amplicons spanning the entire genome were designed using primal. The amplicon length was set to 500bp with 75bp overlap between the different amplicons. The libraries were generated using the native barcode kits from Nanopore (EXP-NBD104 and EXP-NBD114 and SQK-LSK109) and sequenced on a R9.4 flow cell multiplexing up to 24 samples per sequence run. Raw data was demultiplexed, amplicon primers were trimmed and human data was removed by mapping against the human reference genome.</DESCRIPTION>
		<SAMPLE_ATTRIBUTES>
			<SAMPLE_ATTRIBUTE>
				<TAG>collecting institution</TAG>
				<VALUE>not provided</VALUE>
			</SAMPLE_ATTRIBUTE>
			<SAMPLE_ATTRIBUTE>
				<TAG>collection date</TAG>
				<VALUE>$deref_data{$ref}{date}</VALUE>
			</SAMPLE_ATTRIBUTE>
			<SAMPLE_ATTRIBUTE>
				<TAG>collector name</TAG>
				<VALUE>Dutch COVID-19 response team</VALUE>
			</SAMPLE_ATTRIBUTE>
			<SAMPLE_ATTRIBUTE>
				<TAG>geographic location (country and/or sea)</TAG>
				<VALUE>Netherlands</VALUE>
			</SAMPLE_ATTRIBUTE>
			<SAMPLE_ATTRIBUTE>
				<TAG>geographic location (region and locality)</TAG>
				<VALUE>$deref_data{$ref}{region}</VALUE>
			</SAMPLE_ATTRIBUTE>
			<SAMPLE_ATTRIBUTE>
				<TAG>GISAID Accession ID</TAG>
				<VALUE>$deref_data{$ref}{GID}</VALUE>
			</SAMPLE_ATTRIBUTE>
			<SAMPLE_ATTRIBUTE>
				<TAG>host common name</TAG>
				<VALUE>Human</VALUE>
			</SAMPLE_ATTRIBUTE>
			<SAMPLE_ATTRIBUTE>
				<TAG>host health state</TAG>
				<VALUE>not collected</VALUE>
			</SAMPLE_ATTRIBUTE>
			<SAMPLE_ATTRIBUTE>
				<TAG>host scientific name</TAG>
				<VALUE>Homo sapiens</VALUE>
			</SAMPLE_ATTRIBUTE>
			<SAMPLE_ATTRIBUTE>
				<TAG>host sex</TAG>
				<VALUE>not provided</VALUE>
			</SAMPLE_ATTRIBUTE>
			<SAMPLE_ATTRIBUTE>
				<TAG>host subject id</TAG>
				<VALUE>restricted access</VALUE>
			</SAMPLE_ATTRIBUTE>
			<SAMPLE_ATTRIBUTE>
				<TAG>isolate</TAG>
				<VALUE>$deref_data{$ref}{seq_id}</VALUE>
			</SAMPLE_ATTRIBUTE>
			<SAMPLE_ATTRIBUTE>
				<TAG>isolation source host-associated</TAG>
				<VALUE>not collected</VALUE>
			</SAMPLE_ATTRIBUTE>
			<SAMPLE_ATTRIBUTE>
				<TAG>sample capture status</TAG>
				<VALUE>active surveillance in response to outbreak</VALUE>
			</SAMPLE_ATTRIBUTE>
			<SAMPLE_ATTRIBUTE>
				<TAG>ENA-CHECKLIST</TAG>
				<VALUE>ERC000033</VALUE>
			</SAMPLE_ATTRIBUTE>
		</SAMPLE_ATTRIBUTES>
	  </SAMPLE>
EOF


  }
  print {$out} "<SAMPLE_SET>\n".$all_sample."\n</SAMPLE_SET>\n";
  return;
}


sub fill_xml_exp {
  my $data = shift;
  my $outfile = shift;
  my %deref_data = %$data;
  my $ref;
  my $exp_alias;
  
  

  open my $out, '>', $outfile;
  print {$out} '<?xml version="1.0" encoding="UTF-8"?>' . "\n" ;
  my $all_exp; 
  for $ref (keys %deref_data) {
		  $exp_alias = "Exp_" . $ref;
		
	  $all_exp .= <<"EOF";
	   <EXPERIMENT alias="$exp_alias" center_name="Dutch COVID-19 response team">
		   <TITLE>GridION sequencing</TITLE>
		   <STUDY_REF accession="PRJEB39014"/>
		   <DESIGN>
			   <DESIGN_DESCRIPTION/>
			   <SAMPLE_DESCRIPTOR refname="$ref"/>
			   <LIBRARY_DESCRIPTOR>
				   <LIBRARY_NAME/>
				   <LIBRARY_STRATEGY>AMPLICON</LIBRARY_STRATEGY>
				   <LIBRARY_SOURCE>VIRAL RNA</LIBRARY_SOURCE>
				   <LIBRARY_SELECTION>PCR</LIBRARY_SELECTION>
				   <LIBRARY_LAYOUT>
					   <SINGLE/>
				   </LIBRARY_LAYOUT>
			   </LIBRARY_DESCRIPTOR>
		   </DESIGN>
		   <PLATFORM>
			   <OXFORD_NANOPORE>
				   <INSTRUMENT_MODEL>GridION</INSTRUMENT_MODEL>
			   </OXFORD_NANOPORE>
		   </PLATFORM>
		   <EXPERIMENT_ATTRIBUTES>
			   <EXPERIMENT_ATTRIBUTE>
				   <TAG>library preparation date</TAG>
				   <VALUE>not collected</VALUE>
			   </EXPERIMENT_ATTRIBUTE>
		   </EXPERIMENT_ATTRIBUTES>
	   </EXPERIMENT>
EOF


  }
  print {$out} "<EXPERIMENT_SET>\n".$all_exp."\n</EXPERIMENT_SET>\n";
  return;
}

sub fill_xml_run {
  my $data = shift;
  my $md5_info = shift;
  my $outfile = shift;
  my %deref_data = %$data;
  my %deref_md5 = %$md5_info;
  my $ref;
  my $exp_alias;
  my $file_name;
  my $file_name_ENA;
  my $run_name;

  open my $out, '>', $outfile;
  print {$out} '<?xml version="1.0" encoding="UTF-8"?>' . "\n" ;
  my $all_run; 
  for $ref (keys %deref_data) {
		  $exp_alias = "Exp_" . $ref;
		  my ($run) = ($ref =~ /Run(\d{3})_BC\d{2}/);
		  my ($bc) = ($ref =~ /Run\d{3}_(BC\d{2})/); 
		  $file_name = "Run" . $run . "_" . $bc . ".fastq.gz";
		  $file_name_ENA = "run280_370/Run" . $run . "_" . $bc . ".fastq.gz";
		  $run_name = "run" . $run . "_" . $bc;
	  
	  
	  $all_run .= <<"EOF";
		<RUN alias="$run_name" center_name="Dutch COVID-19 response team">
			<EXPERIMENT_REF refname="$exp_alias"/>
			<DATA_BLOCK>
				<FILES>
					<FILE filename="$file_name_ENA" filetype="fastq"
						checksum_method="MD5" checksum="$deref_md5{$file_name}"/>
				</FILES>
			</DATA_BLOCK>
		</RUN>
EOF

  }
  print {$out} "<RUN_SET>\n".$all_run."\n</RUN_SET>\n";
  return;
}

