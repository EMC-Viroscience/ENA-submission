# ENA-submission

This repository contains script, tools, information about the methods/routes used to submit sample/experiment/run to [European Nucleotide Archive (ENA)](https://www.ebi.ac.uk/ena/browser/home).

## Interactive routes

Can be done by connecting on the [Webin submission service](https://www.ebi.ac.uk/ena/submit/sra/#home)

Test can be also done on their [Test Webin submission service](https://wwwdev.ebi.ac.uk/ena/submit/sra/#home)


## Programmatic routes

Different xml files must be created and then submitted using a curl command. 

More information about the xml files (format, etc.) can be found in the [ENA readthedocs](https://ena-docs.readthedocs.io/en/latest/submit/general-guide/programmatic.html)

Curl command for a test submission: 

```bash
curl -u Webin-USER:PASS -F "SUBMISSION=@submission.xml" -F "SAMPLE=@sample.xml" -F "RUN=@run.xml" -F "EXPERIMENT=@exp.xml" "https://wwwdev.ebi.ac.uk/ena/submit/drop-box/submit/" >> runExpLog.txt 2>&1   
```

`runExpLog.txt` file stores the progress and error logs

When tests are successful, *replace* the url https://wwwdev.ebi.ac.uk/ena/submit/drop-box/submit/ with https://www.ebi.ac.uk/ena/submit/drop-box/submit/ for publishing. 


Several parser are available in the script directory for the creation of those xml files. 

## Webin-CLI

Only reads can be submitted using this route, samples or studies must be submitted first using one of the above method. 
