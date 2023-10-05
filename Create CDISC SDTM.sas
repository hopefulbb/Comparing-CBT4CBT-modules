/*Create CDISC SDTM domain datasets*/;

/* Import DRRT baseline and demographics file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/BASEline_vars.xlsx'
dbms = xlsx out = demos replace;
getnames = yes;
options validvarname = v7;
run;

/* Import treatment modules data file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/topicdateandtimevars.xlsx' 
dbms = xlsx out = txmods replace;
getnames = yes;
options validvarname = v7;
run;

/* Import TLFB primary alcohol use file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/fullalcflipwithdates.xlsx' 
dbms = xlsx out = tlfb replace;
getnames = yes;
options validvarname = v7;
run;

/* Import date of randomization file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SpanishCBTRanddates.xlsx'
dbms = xlsx out = randomize replace;
getnames = yes;
options validvarname = v7;
run;

/* Import treatment completion file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/BBSpanishDrugOutcomevarset.xlsx'
dbms = xlsx out = txcompletion replace;
getnames = yes;
options validvarname = v7;
run;

/* Import BSI data file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/BSI.xlsx'
dbms = xlsx out = bsi53 replace;
getnames = yes;
options validvarname = v7;
run;

/* Import patient feedback form data file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/feedback.xlsx'
dbms = xlsx out = feedback replace;
getnames = yes;
options validvarname = v7;
run;



/*Create DM (Demographics) SDTM domain*/;

proc sort data = demos;
by ID;
run;

/*Remove column labels*/
proc datasets lib=work noprint;
  modify demos;
  attrib _all_ label='';
run;

data DM;
length STUDYID $20 DOMAIN $2 SITEID $10 SUBJID $20 USUBJID $40 
	ARM $200 ARMCD $20 ACTARM $200 ACTARMCD $20 ARMNRS $100
	ACTARMUD $200 RFSTDTC $40 RFENDTC $40 RFXSTDTC $40 RFXENDDTC $40
	RFICDTC $40 RFPENDTC $40 COUNTRY $4
	AGEU $10 ETHNIC $60 SEX $2 RACE $100;
set demos(rename = (age = AGE));
	STUDYID = "SPA001";
	DOMAIN = "DM";
	SITEID = "01";
	SUBJID = ID;
	USUBJID = cats(STUDYID, SITEID, SUBJID);

	if (txgroup = 1) then ARM = "TAU + CBT4CBT";
	else if (txgroup = 2) then ARM = "TAU";
	
	if (ARM = "TAU + CBT4CBT") then ARMCD = "C4C";
	else if (ARM = "TAU") then ARMCD = "TAU";

	ACTARM = ARM;
	ACTARMCD = ARMCD;
	COUNTRY = "USA";

	if (gender = 1) then SEX = 'M';
	else if (gender = 2) then SEX = 'F';

	AGEU = "YEARS";
	ETHNIC = "HISPANIC OR LATINO";
	RACE = "UNKOWN";
keep id STUDYID DOMAIN SITEID SUBJID USUBJID ARM ARMCD 
	ACTARM ACTARMCD ARMNRS ACTARMUD RFSTDTC RFENDTC 
	RFXSTDTC RFXENDDTC RFICDTC RFPENDTC AGE AGEU 
	SEX ETHNIC RACE COUNTRY;
run;

data DM;
merge DM randomize;
by id;
RFSTDTC = put(randdate,yymmdd10.);
drop id randdate;
run;

data DM;
retain STUDYID DOMAIN SITEID SUBJID USUBJID ARM ARMCD 
	ACTARM ACTARMCD ARMNRS ACTARMUD RFSTDTC RFENDTC 
	RFXSTDTC RFXENDDTC RFICDTC RFPENDTC AGE AGEU 
	SEX ETHNIC RACE COUNTRY;
set DM;
run;



/*Create MH (Medical History) SDTM domain*/;
data MH;
set DM(keep = STUDYID DOMAIN SUBJID USUBJID);
DOMAIN = "MH";
ID = input(SUBJID, 20.);
drop SUBJID;
run;
data currentaud;
merge MH demos;
by ID;
MHTERM = "CURRENT ALCOHOL ABUSE OR DEPENDENCE";
MHDECOD = "CURRENT";
MHEVDTYP = "DIAGNOSIS";
MHPRESP = "Y";
if alccur = 1 then MHOCCUR = "Y";
	else if alccur = 0 then MHOCCUR = "N";
keep STUDYID DOMAIN USUBJID MHTERM MHDECOD MHEVDTYP MHPRESP MHOCCUR;
run;
data primary;
merge MH demos;
by ID;
MHTERM = "PRIMARY DRUG USE IS ALCOHOL";
MHDECOD = "PRIMARY";
MHEVDTYP = "DIAGNOSIS";
MHPRESP = "Y";
if prmdrg = 1 then MHOCCUR = "Y";
	else if prmdrg ^= 0 then MHOCCUR = "N";
keep STUDYID DOMAIN USUBJID MHTERM MHDECOD MHEVDTYP MHPRESP MHOCCUR;
run;
data MH;
set currentaud primary;
run;
proc sort data = MH;
by USUBJID MHTERM;
run;



/*Create DS (Disposition) SDTM domain*/;
data rands;
set DM(keep = SUBJID STUDYID DOMAIN USUBJID);
id = input(compress(SUBJID), best.);
DOMAIN = "DS";
run;
data rands;
merge rands randomize;
by id;
keep STUDYID DOMAIN USUBJID randdate;
run;

data DS;
set rands;
length DSSEQ 8. DSTERM $200 DSDECOD $200 DSCAT $200 DSSTDTC $40;
DSTERM = "RANDOMIZED";
DSDECOD = "RANDOMIZED";
DSCAT = "PROTOCOL MILESTONE";
DSSTDTC = put(randdate,yymmdd10.);
drop randdate;
run;
proc sort data = DS;
by USUBJID DSSTDTC;
run;
data DS;
set DS;
count + 1;
by USUBJID;
if first.USUBJID then count = 1;
DSSEQ = count;
drop count;
run;



/*Create EC (Exposure as Collected) SDTM domain*/;
/*Merge DM ID variables, randomization date, and module completion data*/
proc sort data = txmods;
by ID;
run;
proc sort data = DS;
by USUBJID;
run;
proc sort data = DM;
by SUBJID;
run;

data ids;
merge DM DS;
by USUBJID;
ID = input(compress(SUBJID), best.);
randomization_date = input(DSSTDTC, yymmdd10.);
format randomization_date yymmdd10.;
keep ID STUDYID USUBJID randomization_date;
run;

data EC;
merge ids txmods;
by ID;
if topic ^= .;
drop ID;
run;
data EC;
length DOMAIN $2 ECSEQ 8 ECMOOD $40 ECPRESP $2 ECTRT $100 
	ECDOSE 8 ECDOSU $40 ECDOSFRM $20 ECSTDTC $40 ECENDTC $40;
set EC;
	DOMAIN = "EC";
	ECSEQ = topic;
	ECMOOD = "PERFORMED";
	ECPRESP = "Y";
	ECTRT = catx(" ", "MODULE", topic);
	ECDOSE = tottime;
	ECDOSU = "min";
	ECDOSFRM = "NOT APPLICABLE";
	ECSTDTC = put(datecompmmod,yymmdd10.);
	ECENDTC = put(datecompmmod,yymmdd10.);

drop topic tottime datecompmmod ;
run;

/*Create dataset to document scheduled exposures to treatment modules*/
proc sort data = EC;
by USUBJID ECSEQ;
run;

proc sql;
	create table ids as
		select unique USUBJID
		from EC;
	create table seqs as
		select unique ECSEQ
		from EC;
	create table scheduled as
		select *
		from ids, seqs;
quit;
proc sort data = scheduled;
by USUBJID ECSEQ;
run;
data scheduled;
merge scheduled EC;
by USUBJID;
ECMOOD = "SCHEDULED";
ECTRT = catx(" ", "MODULE", ECSEQ);
ECDOSE = 40;
adjustdate = intnx('day', randomization_date , (ECSEQ-1)*7);
ECSTDTC = put(adjustdate,yymmdd10.);
ECENDTC = ECSTDTC;
keep USUBJID ECSEQ ECMOOD ECTRT ECDOSE ECDOSU ECDOSFRM ECSTDTC ECENDTC randomization_date;
run;


/*Insert missed occurrences of treatment modules*/
data missed;
merge EC scheduled;
by USUBJID;
ECMOOD = "PERFORMED";
drop ECTRT ECDOSE ECSTDTC ECENDTC;
run; 
data EC;
merge EC missed;
by USUBJID ECSEQ;
run;

data EC;
length ECOCCUR $8 ECREASOC $100;
set EC;
	if ECDOSE = . then ECOCCUR = "N";
	else if ECDOSE ^= . then ECOCCUR = "Y";

	if ECDOSE = . then ECREASOC = "PATIENT MISSED";
	else if ECDOSE ^= . then ECREASOC = "";

	if ECTRT = " " then ECTRT = catx(" ", "MODULE", ECSEQ);
run;

data EC;
   retain STUDYID DOMAIN USUBJID ECSEQ ECMOOD 
		ECPRESP ECOCCUR ECREASOC ECTRT ECDOSE ECDOSU 
		ECDOSFRM ECSTDTC ECENDTC randomization_date;
   set EC;
run;

/*Add missing dates to ECMOOD = PERFORMED rows*/
data missing_performed;
set scheduled;
missing_startdates = ECSTDTC;
missing_enddates = ECENDTC;
keep USUBJID ECSEQ missing_startdates missing_enddates;
run;

data EC;
merge EC missing_performed;
by USUBJID ECSEQ;
if ECSTDTC = " " then ECSTDTC = missing_startdates;
if ECENDTC = " " then ECENDTC = missing_enddates;
drop missing_startdates missing_enddates;
run;

/*Combine scheduled and performed rows*/
proc sort data = scheduled;
by USUBJID ECSTDTC ECSEQ;
run;
proc sort data = EC;
by USUBJID ECSTDTC ECSEQ;
run;

data EC;
retain STUDYID DOMAIN USUBJID ECSEQ ECTRT ECMOOD ECPRESP ECOCCUR
	ECREASOC ECDOSE ECDOSU ECDOSFRM ECSTDTC ECENDTC randomization_date;
set scheduled EC;
STUDYID = "SPA001";
DOMAIN = "EC";
ECSTDY = 1 + (input(ECSTDTC, yymmdd10.) - randomization_date);
ECENDY = 1 + (input(ECENDTC, yymmdd10.) - randomization_date);
drop randomization_date;
run;
proc sort data = EC;
by USUBJID ECSTDTC descending ECSEQ;
run;
data EC;
  set EC;
  new_ECSEQ + 1;
  by USUBJID;
  if first.USUBJID then new_ECSEQ = 1;
ECSEQ = new_ECSEQ;
drop new_ECSEQ;
run;



/*Create EX (Exposure) SDTM domain*/;
data EX;
set EC;
if ECOCCUR = "Y";
DOMAIN = "EX";
drop ECMOOD ECPRESP ECOCCUR ECREASOC;
run;
/*Replace prefix from EC to EX*/
proc sql noprint;
   select cats(name, "=", tranwrd(name, "EC", "EX"))
          into :colnames
          separated by ' '
          from dictionary.columns
          where libname = 'WORK' and memname = 'EX';
quit;

proc datasets library = work noprint;
   modify EX;
   rename &colnames;
quit;
proc sort data = EX;
by USUBJID EXSTDTC descending EXSEQ;
run;

data EX;
  set EX;
  new_EXSEQ + 1;
  by USUBJID;
  if first.USUBJID then new_EXSEQ = 1;
EXSEQ = new_EXSEQ;
drop new_EXSEQ;
run;



/*Use EX and DS dates for DM RF dates */;
proc sort data = EX;
by USUBJID EXSTDTC;
run;
data dates1;
set EX(keep = USUBJID EXSTDTC);
by USUBJID;
if first.USUBJID then output;
run;
data dates2;
set EX(keep = USUBJID EXENDTC);
by USUBJID;
if last.USUBJID then output;
run;

data dates;
merge dates1(in = a) dates2;
by USUBJID;
if a then output;
run;
data DM;
merge DM dates;
by USUBJID;
RFXSTDTC = EXSTDTC;
RFXENDDTC = EXENDTC;
RFENDTC = RFXENDDTC;
drop EXSTDTC EXENDTC;
run;



/*Create TS (Trial Summary) SDTM domain*/;
data TS;
set DM(keep = STUDYID DOMAIN);
length TSSEQ 8. TSGRPID $2 TSPARMCD $8 TSPARM $8 TSVAL $40 TSVCDREF $20;
DOMAIN = "TS";
if _n_ = 1 then output;
run;

data TS;
infile datalines dsd;
informat STUDYID $20. DOMAIN $2. TSSEQ 8. TSGRPID $8. TSPARMCD $8. 
	TSPARM $40.	TSVAL $200. TSVALCD $20. TSVCDREF $20. TSVCDVER $20.;
input STUDYID DOMAIN TSSEQ TSGRPID 
	TSPARMCD TSPARM TSVAL TSVALCD TSVCDREF TSVCDVER;
datalines;
,,,, TITLE, Trial Title, "Computer Based Training in CBT for Spanish-speaking Substance Users", , , 
,,,, SPONSOR, "Clinical Study Sponsor", "National Institute on Drug Abuse", , , 
,,,, TRT, "Investigational Therapy or Treatment", "Spanish CBT4CBT", , , 
,,,, INDIC, "Trial Disease/Condition Indication", "DSM-IV Alcohol Abuse", "F10.1", "ICD", "ICD-10-CM"
,,,, INDIC, "Trial Disease/Condition Indication", "DSM-IV Alcohol Dependence", "F10.2", "ICD", "ICD-10-CM"
,,,, TCNTRL, "Control Type", "ACTIVE", "C49649", "CDISC CT", "2023-06-30"
,,,, TDIGRP, "Diagnosis Group", "DSM-IV Alcohol Abuse", "F10.1", "ICD", "ICD-10-CM"
,,,, TDIGRP, "Diagnosis Group", "DSM-IV Alcohol Dependence", "F10.2", "ICD", "ICD-10-CM"
,,,, TINDTP, "Trial Intent Type", "TREATMENT", "C49656", "CDISC CT", "2023-06-30"
,,,, TTYPE, "Trial Type", "EFFICACY", "C49666", "CDISC CT", "2023-06-30"
,,,, TTYPE, "Trial Type", "SAFETY", "C49667", "CDISC CT", "2023-06-30"
,,,, FCNTRY, "Planned Country of Investigational Sites", "USA", , "ISO 3166-1 Alpha-3", 
,,,, RANDOM, "Trial is Randomized ", "Y", "C49488", "CDISC CT", "2023-06-30" 
,,,, SEXPOP, "Sex of Participants", "BOTH", "C49636", "CDISC CT", "2023-06-30" 
,,,, AGEMIN, "Planned Minimium Age of Subjects", "P18Y", , "ISO 8601", 
,,,, REGID, "Registry Identifier", "NCT02043210", "NCT02043210", "ClinicalTrials.gov", 
,,,, STOPRULE, "Study Stop Rules", "End of Budget Period", , ,
,,,, TBLIND, "Trial Blinding Schema", "OPEN LABEL", "C15228", "CDISC CT", "2023-06-30"
,,,, ADDON, "Added on to Existing Treatments", "Y", "C49488", "CDISC CT", "2023-06-30"
,,,, INTMODEL, "Intervention Model", "PARALLEL", "C82639", "CDISC CT", "2023-06-30"
,,,, NARMS, "Planned Number of Arms", "2", "C49667", "CDISC CT", "2023-06-30"
,,,, STYPE, "Study Type", "INTERVENTIONAL", "C98388", "CDISC CT", "2023-06-30"
,,,, INTTYPE, "Intervention Type", "BEHAVIORAL THERAPY ", "C15184", "CDISC CT", "2023-06-30"
,,,, OBJPRIM, "Trial Primary Objective", "Reduction in substance use over time during the 8-week treatment period", , ,
,,,, OBJSEC, "Trial Secondary Objective", "Increase in coping skills over time during the 8-week treatment period", , ,
,,,, OUTMSPRI, "Primary Outcome Measure", "Timeline Followback Calendar", , ,
,,,, OUTMSPRI, "Primary Outcome Measure", "Urine Toxicology Screening", , ,
,,,, OUTMSSEC, "Secondary Outcome Measure", "Drug Risk Response Test - Spanish Version", , ,
,,,, ADAPT, "Adaptive Design", "N", "C49487", "CDISC CT", "2023-06-30"
,,,, SSTDTC, "Study Start Date", "2014-01-10", , "ISO 8601",
,,,, SSENDTC, "Study End Date", "2020-03-06", , "ISO 8601",
,,,, DCUTDTC , "Data Cutoff Date", "2017-09-11", , "ISO 8601",
,,,, DCUTDESC , "Data Cutoff Description", "PRIMARY ANALYSIS", , ,
,,,, ACTSUB, "Actual Number of Subjects", "99", , ,
,,,, PLANSUB, "Planned Number of Subjects", "100", , ,
,,,, LENGTH, "Trial Length", "P8W", , "ISO 8601",
,,,, HLTSUBJI, "Healhty Subject Indicator", "N", "C49487", "CDISC CT", "2023-06-30"
;
run;
proc sort data = ts;
by TSPARMCD;
run;
data TS;
set TS;
count + 1;
by TSPARMCD;
STUDYID = "SPA001";
DOMAIN = "TS";
TSGRPID = "A";
if first.TSPARMCD then count = 1;
TSSEQ = count;
drop count;
run;



/*Create TA (Trial Arm) SDTM domain*/;
data TA;
infile datalines dsd;
informat STUDYID $20. DOMAIN $2. ARMCD $20. ARM $100.  
	TAERORD 8.	ETCD $100. ELEMENT $100. TABRANCH $100.
	TATRANS $100. EPOCH $60.;
input STUDYID DOMAIN ARMCD ARM TAERORD ETCD ELEMENT
	TABRANCH TATRANS EPOCH;
datalines;
 , , "C4C", , 1, "SCRN", , , ,
 , , "C4C", , 2, "RI", , , ,
 , , "C4C", , 3, "C4C", , , ,
 , , "C4C", , 4, "FU", , , ,
 , , "TAU", , 1, "SCRN", , , ,
 , , "TAU", , 2, "RI", , , ,
 , , "TAU", , 3, "TAU", , , ,
 , , "TAU", , 4, "FU", , , ,
;
run;
data TA;
set TA;
STUDYID = "SPA001";
DOMAIN = "TA";
	if (ARMCD = "C4C") then ARM = "TAU + CBT4CBT";
	else if (ARMCD = "TAU") then ARM = "TAU";

	if (ETCD = "SCRN") then ELEMENT = "Screen";
	else if (ETCD = "RI") then ELEMENT = "Run-In";
	else if (ETCD = "FU") then ELEMENT = "Follow Up";
	else if (ETCD = "C4C") then ELEMENT = "TAU + CBT4CBT";
	else if (ETCD = "TAU") then ELEMENT = "TAU";

	if (ETCD = "SCRN") then EPOCH = "SCREENING";
	else if (ETCD = "RI") then EPOCH = "RUN-IN";
	else if (ETCD = "FU") then EPOCH = "FOLLOW UP";
	else if (ETCD = "C4C") then EPOCH = "TREATMENT";
	else if (ETCD = "TAU") then EPOCH = "TREATMENT";

	if (ETCD = "C4C") then TABRANCH = "Randomized to TAU + CBT4CBT";
	else if (ETCD = "TAU") then TABRANCH = "Randomized to TAU";
run;



/*Create RS (Clinical Classification and Disease Response) SDTM domain*/;
data alcdx;
set DM(keep = SUBJID STUDYID DOMAIN USUBJID);
id = input(compress(SUBJID), best.);
DOMAIN = "RS";
run;
data alcdx;
merge alcdx demos;
by id;
keep STUDYID DOMAIN USUBJID alccur;
run;

data RS;
set alcdx;
length RSSEQ 8. RSTESTCD $8 RSTEST $40 RSCAT $40 RSORRES $40 
	RSSTRESC $20 RSSTRESN 8. RSLOBXFL $20 VISITNUM 8. RSDTC $20;
RSTESTCD = "SCIDALC";
RSTEST = "SCID-IV Alcohol Abuse or Dependence";
RSCAT = "SCID-IV SPANISH VERSION";
RSLOBXFL = "Y";
VISITNUM = 1;
RSSTRESN = alccur;

	if alccur = 1 then RSORRES = "Current Diagnosis";
	else if alccur = 0 then RSORRES = "No Current Diagnosis";

RSSTRESC = upcase(RSORRES);
drop alccur;
run;
proc sort data = RS;
by USUBJID VISITNUM RSTESTCD;
run;
data RS;
set RS;
count + 1;
by USUBJID VISITNUM RSTESTCD;
if first.RSTESTCD then count = 1;
RSSEQ = count;
drop count;
run;



/*Create QS (Questionnaires) SDTM domain*/;
data asi;
set DM(keep = SUBJID STUDYID DOMAIN USUBJID RFSTDTC RFXSTDTC);
id = input(compress(SUBJID), best.);
DOMAIN = "QS";
QSDTC = input(RFSTDTC, yymmdd10.);
first_tx = input(RFXSTDTC, yymmdd10.);
format QSDTC first_tx yymmdd10.;
run;
data asi;
merge asi demos;
by id;
alccom = round(alccom, 0.01);
keep STUDYID DOMAIN USUBJID QSDTC first_tx alccom;
run;

data asi;
set asi;
length QSSEQ 8. QSTESTCD $8 QSTEST $40 QSCAT $40 QSORRES $200 
	QSSTRESC $20 QSSTRESN 8. QSLOBXFL $2 VISITNUM 8. QSDTC 8.;
QSTESTCD = "ASIALC";
QSTEST = "Addiction Severity Index - Alcohol composite";
QSCAT = "ADDICTION SEVERITY INDEX SPANISH VERSION";
if QSDTC < first_tx then QSLOBXFL = "Y";
VISITNUM = 1;
QSORRES = alccom;
QSSTRESC = alccom;
QSSTRESN = alccom;
drop alccom first_tx;
run;

data bsi;
set DM(keep = SUBJID STUDYID DOMAIN USUBJID);
id = input(compress(SUBJID), best.);
DOMAIN = "QS";
run;

proc sort data = bsi53;
by id visdate;
run;

data bsi53;
set bsi53;
BSIM = mean(of bsi1 - bsi53);
if visweek = 13 then visweek = 12;
run;

proc transpose data = bsi53 out = bsi_long;
by id visdate;
var bsi1-bsi53 BSIM;
run;
proc transpose data = bsi53 out = bsi_long2;
by id visweek;
var bsi1-bsi53 BSIM;
run;

data bsi_long;
set bsi_long;
set bsi_long2(keep = visweek);
length VISITNUM 8.;
VISITNUM = visweek + 1;
run;



data bsi;
merge bsi(in = b) bsi_long(in = a);
by id;
if a and b then output;
run;
data bsi_firsttx;
set DM(keep = SUBJID RFXSTDTC);
id = input(compress(SUBJID), best.);
first_tx = input(RFXSTDTC, yymmdd10.);
format first_tx yymmdd10.;
keep id first_tx;
run;
data bsi;
merge bsi bsi_firsttx;
by id;
if visdate < first_tx then bsfl = "Y"; 
run;

proc freq data = bsi noprint;
table id*visweek / out = bsi_lobs;
where bsfl = "Y";
run;
data bsi_lobs;
set bsi_lobs(keep = id visweek);
by id;
lobfl = "Y";
if last.id then output;
run;
data bsi;
merge bsi bsi_lobs;
by id visweek;
run;
data bsi;
set bsi;
length QSSEQ 8. QSTESTCD $8 QSTEST $40 QSCAT $40 QSORRES $200 
	QSSTRESC $20 QSSTRESN 8. QSLOBXFL $2 VISITNUM 8. QSDTC 8.;
QSTESTCD = prxchange('s/BSI/BSI53_/', -1, _name_);
QSCAT = "BSI-53";
QSSTRESC = put(col1, 8.);
QSSTRESN = col1;
QSDTC = VISDATE;
QSLOBXFL = lobfl;

if QSSTRESN = 0 then QSORRES = "Nada";
 else if QSSTRESN = 1 then QSORRES = "Un Poco";
 else if QSSTRESN = 2 then QSORRES = "Moderadamente";
 else if QSSTRESN = 3 then QSORRES = "Bastante";
 else if QSSTRESN = 4 then QSORRES = "Mucho";

if _name_ = "BSIM" then QSORRES = "";
if _name_ = "BSIM" then QSSTRESC = "";

if _name_ = "BSI1" then QSTEST = "BSI1-Nerviosismo o temblor";
	else if _name_ = "BSI2" then QSTEST = "BSI2-Desmayo o mareos";
	else if _name_ = "BSI3" then QSTEST = "BSI3-Controlar sus pensamientos";
	else if _name_ = "BSI4" then QSTEST = "BSI4-Otros son culpables";
	else if _name_ = "BSI5" then QSTEST = "BSI5-Dificultad para recordar cosas";
	else if _name_ = "BSI6" then QSTEST = "BSI6-Fácilmente molesto o irritado";
	else if _name_ = "BSI7" then QSTEST = "BSI7-Dolores en corazón o pecho";
	else if _name_ = "BSI8" then QSTEST = "BSI8-Asustado en espacios abiertos";
	else if _name_ = "BSI9" then QSTEST = "BSI9-Poner fin a su vida";
	else if _name_ = "BSI10" then QSTEST = "BSI10-No confiar en mayoría";
	else if _name_ = "BSI11" then QSTEST = "BSI11-Falta de apetito";
	else if _name_ = "BSI12" then QSTEST = "BSI12-Sustos repentinos";
	else if _name_ = "BSI13" then QSTEST = "BSI13-Explosiones de enojo ";
	else if _name_ = "BSI14" then QSTEST = "BSI14-Solo aun cuando está acompañado";
	else if _name_ = "BSI15" then QSTEST = "BSI15-Sentirse impedido";
	else if _name_ = "BSI16" then QSTEST = "BSI16-Sentirse solo";
	else if _name_ = "BSI17" then QSTEST = "BSI17-Sentimientos de tristeza";
	else if _name_ = "BSI18" then QSTEST = "BSI18-No sentir interés";
	else if _name_ = "BSI19" then QSTEST = "BSI19-Sentirse con miedo";
	else if _name_ = "BSI20" then QSTEST = "BSI20-Sentimientos fácilmente herido";
	else if _name_ = "BSI21" then QSTEST = "BSI21-La gente no es amigable";
	else if _name_ = "BSI22" then QSTEST = "BSI22-Sentirse inferior";
	else if _name_ = "BSI23" then QSTEST = "BSI23-Náuseas o malestar";
	else if _name_ = "BSI24" then QSTEST = "BSI24-Otros lo miran o hablan";
	else if _name_ = "BSI25" then QSTEST = "BSI25-Dificultad para dormirse";
	else if _name_ = "BSI26" then QSTEST = "BSI26-Revisar lo que hace";
	else if _name_ = "BSI27" then QSTEST = "BSI27-Dificultad tomar decisiones";
	else if _name_ = "BSI28" then QSTEST = "BSI28-Miedo de viajar en autobases";
	else if _name_ = "BSI29" then QSTEST = "BSI29-Falta de aire";
	else if _name_ = "BSI30" then QSTEST = "BSI30-Cambios repentinos de temperatura";
	else if _name_ = "BSI31" then QSTEST = "BSI31-Evitar ciertas cosas";
	else if _name_ = "BSI32" then QSTEST = "BSI32-Mente en blanco";
	else if _name_ = "BSI33" then QSTEST = "BSI33-Adormecimiento u hormigueo";
	else if _name_ = "BSI34" then QSTEST = "BSI34-Castigado por sus pecados";
	else if _name_ = "BSI35" then QSTEST = "BSI35-Sin esperanza";
	else if _name_ = "BSI36" then QSTEST = "BSI36-Dificultad concentrarse";
	else if _name_ = "BSI37" then QSTEST = "BSI37-Sentirse débil";
	else if _name_ = "BSI38" then QSTEST = "BSI38-Sentirse tenso";
	else if _name_ = "BSI39" then QSTEST = "BSI39-Pensar en la muerte";
	else if _name_ = "BSI40" then QSTEST = "BSI40-Necesidad de golpear";
	else if _name_ = "BSI41" then QSTEST = "BSI41-Necesidad de romper";
	else if _name_ = "BSI42" then QSTEST = "BSI42-Consciente de sí mismo";
	else if _name_ = "BSI43" then QSTEST = "BSI43-Incomodo al estar en grupos";
	else if _name_ = "BSI44" then QSTEST = "BSI44-Nunca sentrise cerca";
	else if _name_ = "BSI45" then QSTEST = "BSI45-Ataques de terror";
	else if _name_ = "BSI46" then QSTEST = "BSI46-Frecuentes discusiones";
	else if _name_ = "BSI47" then QSTEST = "BSI47-Nervioso cuando solo";
	else if _name_ = "BSI48" then QSTEST = "BSI48-No le reconocen sus logros";
	else if _name_ = "BSI49" then QSTEST = "BSI49-Inquieto que no permancer sentado";
	else if _name_ = "BSI50" then QSTEST = "BSI50-Usted no vale nada";
	else if _name_ = "BSI51" then QSTEST = "BSI51-Gente se aprovechará";
	else if _name_ = "BSI52" then QSTEST = "BSI52-Sentimientos de culpabilidad";
	else if _name_ = "BSI53" then QSTEST = "BSI53-Mal con su mente";
	else if _name_ = "BSIM" then QSTEST = "BSI53-Mean score";

format QSDTC yymmdd10.;
keep STUDYID DOMAIN USUBJID QSSEQ QSTESTCD QSTEST QSCAT QSORRES 
	QSSTRESC QSSTRESN QSLOBXFL VISITNUM QSDTC; 
run;


data pff;
set DM(keep = SUBJID STUDYID DOMAIN USUBJID);
id = input(compress(SUBJID), best.);
DOMAIN = "QS";
run;

data feedback;
set feedback;
FEED00 = module;
modc = put(module, 8.);
VISITNUM = visweek;
run;
proc sort data = feedback;
by id visdate VISITNUM modc;
run;
proc transpose data = feedback out = pff_long;
by id visdate VISITNUM modc;
var feed00-feed08 feed11a feed12;
run;
data pff_long;
set pff_long;
if prxmatch("/FEED11A|FEED12/i", _name_) = 0 then num = compress(col1);
numeric = input(num, 8.);
if prxmatch("/FEED11A|FEED12/i", _name_) > 0 then qualitative = trim(col1);
drop num col1;
run;

data pff;
merge pff(in = b) pff_long(in = a);
by id;
if a and b then output;
run;

data pff;
set pff;
length QSSEQ 8. QSTESTCD $8 QSTEST $40 QSCAT $40 QSORRES $200 
	QSSTRESC $20 QSSTRESN 8. QSLOBXFL $2 VISITNUM 8. QSDTC 8.;
QSTESTCD = prxchange('s/FEED/PFF_/', -1, _name_);
QSCAT = "CBT4CBT PATIENT FEEDBACK FORM";
QSSTRESC = put(numeric, 8.);
QSSTRESN = numeric;
QSDTC = VISDATE;
QSLOBXFL = " ";

if QSSTRESN = 0 then QSORRES = "Nada";
 else if QSSTRESN = 1 then QSORRES = "Un Poco";
 else if QSSTRESN = 2 then QSORRES = "Moderadamente";
 else if QSSTRESN = 3 then QSORRES = "Bastante";
 else if QSSTRESN = 4 then QSORRES = "Mucho";

if _name_ in ("FEED06", "FEED08") and QSSTRESN = 0 then
	QSORRES = "No";
	else if _name_ in ("FEED06", "FEED08") and QSSTRESN = 1 then
	QSORRES = "Yes";

if _name_ in ("FEED00") then QSORRES = "";

if prxmatch("/FEED11A|FEED12/i", _name_) > 0 then QSORRES = qualitative;
if prxmatch("/FEED11A|FEED12/i", _name_) > 0 then QSSTRESC = "";


if _name_ = "FEED00" then QSTEST = "PFF_00-Module theme";
	else if _name_ = "FEED01" then QSTEST = "PFF_01-Efectivo";
	else if _name_ = "FEED02" then QSTEST = "PFF_02-Nueva información";
	else if _name_ = "FEED03" then QSTEST = "PFF_03-Información aplica";
	else if _name_ = "FEED04" then QSTEST = "PFF_04-Fácil navegar programa";
	else if _name_ = "FEED05" then QSTEST = "PFF_05-Divertido";
	else if _name_ = "FEED06" then QSTEST = "PFF_06-Completó práctica";
	else if _name_ = "FEED07" then QSTEST = "PFF_07-Relaciona con obstáculos";
	else if _name_ = "FEED08" then QSTEST = "PFF_08-Problemas de computadora";
	else if _name_ = "FEED11A" then QSTEST = "PFF_11A-Describe problema";
	else if _name_ = "FEED12" then QSTEST = "PFF_12-Comentarios y opiniones";


if _name_ = "FEED00" and numeric = 1 then QSORRES = "Desencadenantes";
	else if _name_ = "FEED00" and numeric = 2 then QSORRES = "Valer punto de vista";
	else if _name_ = "FEED00" and numeric = 3 then QSORRES = "Manejando deseos";
	else if _name_ = "FEED00" and numeric = 4 then QSORRES = "Para y piénsalo";
	else if _name_ = "FEED00" and numeric = 5 then QSORRES = "Resolviendo problema";
	else if _name_ = "FEED00" and numeric = 6 then QSORRES = "Contra corriente";
	else if _name_ = "FEED00" and numeric = 7 then QSORRES = "Practicando responsabilidad";


format QSDTC yymmdd10.;
keep STUDYID DOMAIN USUBJID QSSEQ QSTESTCD QSTEST QSCAT QSORRES 
	QSSTRESC QSSTRESN QSLOBXFL VISITNUM QSDTC; 
run;


data QS;
set asi bsi pff;
if QSSTRESN = . then QSSTRESC = "";
run;

proc sort data = QS;
by USUBJID QSDTC VISITNUM QSTESTCD;
run;
data QS;
set QS;
count + 1;
by USUBJID QSDTC VISITNUM QSTESTCD;
if first.USUBJID then count = 1;
QSSEQ = count;
drop count;
run;



/*Create SU (Substance Use) SDTM domain*/;
data alcohol;
set DM(keep = SUBJID STUDYID DOMAIN USUBJID RFSTDTC);
id = input(compress(SUBJID), best.);
DOMAIN = "SU";
run;
data alcohol;
merge alcohol tlfb;
by id;
keep STUDYID DOMAIN USUBJID RFSTDTC caldate alc;
run;

data SU;
set alcohol;
length SUSEQ 8. SUTRT $40 SUCAT $40 SUSTAT $20 SUREASND $200
	SUDOSE 8. SUDOSU $40 SUDOSFRQ $40 SUSTDTC $40 SUENDTC $40;
SUTRT = "ANY ALCOHOL CONSUMPTION";
SUCAT = "ALCOHOL";
SUDOSE = alc;
SUDOSU = "QUANTITY SUFFICIENT";
SUDOSFRQ = "UNKNOWN";
SUSTDTC = put(caldate,yymmdd10.);
SUENDTC = put(caldate,yymmdd10.);
SUSTDY = 1 + (caldate - input(RFSTDTC, yymmdd10.));
SUENDY = 1 + (caldate - input(RFSTDTC, yymmdd10.));

	if SUDOSE = . then SUSTAT = "NOT DONE";
	if SUDOSE = . then SUREASND = "Subject did not complete TLFB";

drop caldate alc RFSTDTC;
run;
proc sort data = SU;
by USUBJID SUSTDTC SUTRT;
run;
data SU;
set SU;
count + 1;
by USUBJID;
if first.USUBJID then count = 1;
SUSEQ = count;
drop count;
run;



/*Create SUPPSU (Supplemental SU) SDTM domain*/;
/*Identify days of the week and holidays*/;
data weekdays;
set SU(keep = STUDYID USUBJID SUSEQ SUSTDTC);
RDOMAIN = "SU";
IDVAR = "SUSEQ";
IDVARVAL = SUSEQ;
length QNAM $8 QLABEL $40 QVAL $20;
QNAM = "SUDW";
QLABEL = "Day of the Week";
date = input(SUSTDTC, yymmdd10.);
QVAL = put(date, dowName.);
QORIG = "Derived";
keep STUDYID RDOMAIN USUBJID IDVAR IDVARVAL QNAM QLABEL QVAL QORIG;
run;

data holidays;
set SU(keep = STUDYID USUBJID SUSEQ SUSTDTC);
RDOMAIN = "SU";
IDVAR = "SUSEQ";
IDVARVAL = SUSEQ;
length QNAM $8 QLABEL $40 QVAL $20;
QNAM = "SUHD";
QLABEL = "Holiday or Eve Before Holiday";
date = input(SUSTDTC, yymmdd10.);
if (holidaytest("Christmas", date) = 1) then QVAL = "Christmas";
	else if (holidaytest("Christmas", date + 1) = 1) then QVAL = "Christmas Eve"; 
	else if (holidaytest("Newyear", date) = 1) then QVAL = "New Year's";
	else if (holidaytest("Newyear", date + 1) = 1) then QVAL = "New Year's Eve";
	else if (holidaytest("Thanksgiving", date) = 1) then QVAL = "Thanksgiving";
	else if (holidaytest("Thanksgiving", date + 1) = 1) then QVAL = "Thanksgiving Eve";
	else if (holidaytest("Memorial", date) = 1) then QVAL = "Memorial";
	else if (holidaytest("Memorial", date + 1) = 1) then QVAL = "Memorial Eve";
	else if (holidaytest("Labor", date) = 1) then QVAL = "Labor";
	else if (holidaytest("Labor", date + 1) = 1) then QVAL = "Labor Eve";
	else if (holidaytest("Usindependence", date) = 1) then QVAL = "Independence";
	else if (holidaytest("Usindependence", date + 1) = 1) then QVAL = "Independence Eve";
	else if (holidaytest("Uspresidents", date) = 1) then QVAL = "Presidents";
	else if (holidaytest("Uspresidents", date + 1) = 1) then QVAL = "Presidents Eve";
	else if (holidaytest("Halloween", date) = 1) then QVAL = "Halloween";
QORIG = "Derived";
keep STUDYID RDOMAIN USUBJID IDVAR IDVARVAL QNAM QLABEL QVAL QORIG;
run;

data SUPPSU;
set weekdays holidays;
run;
proc sort data = SUPPSU;
by USUBJID IDVAR IDVARVAL;
run;


/*Export SDTM domains to Excel files*/;
proc export data = DM
    outfile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/DM.xlsx'
    dbms = xlsx
    replace;
run;
proc export data = MH
    outfile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/MH.xlsx'
    dbms = xlsx
    replace;
run;
proc export data = DS
    outfile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/DS.xlsx'
    dbms = xlsx
    replace;
run;
proc export data = EC
    outfile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/EC.xlsx'
    dbms = xlsx
    replace;
run;
proc export data = EX
    outfile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/EX.xlsx'
    dbms = xlsx
    replace;
run;
proc export data = TS
    outfile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/TS.xlsx'
    dbms = xlsx
    replace;
run;
proc export data = TA
    outfile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/TA.xlsx'
    dbms = xlsx
    replace;
run;
proc export data = RS
    outfile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/RS.xlsx'
    dbms = xlsx
    replace;
run;
proc export data = QS
    outfile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/QS.xlsx'
    dbms = xlsx
    replace;
run;
proc export data = SU
    outfile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/SU.xlsx'
    dbms = xlsx
    replace;
run;
proc export data = SUPPSU
    outfile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/SUPPSU.xlsx'
    dbms = xlsx
    replace;
run;



















/*ADaM datasets*/;


/*Create ADSL (Subject-Level Analysis Data Set) ADaM domain*/;
/*Select columns from DM*/
data ADSL;
set DM;
keep STUDYID USUBJID SUBJID SITEID AGE AGEU SEX RACE
	ETHNIC ARM ARMCD ACTARMCD ACTARM RFSTDTC RFENDTC
	COUNTRY;
run;
data ADSL;
set ADSL;
TRTSDT = RFSTDTC;
TRTEDT = RFENDTC;
RANDFL = "Y";
ITTFL = "Y";
run;
/*Create AAGE as log of AGE - minimum age in sample (= 21) + 1*/
proc sql;
create table ADSL as 
select *, log(AGE - min(AGE) + 1) as AAGE
from ADSL;
quit;
/*Use EC dataset to create columns for planned and actual treatment periods*/
data ec_to_adsl;
set EC(keep = USUBJID ECTRT ECDOSE ECDOSU ECMOOD ECSTDTC ECENDTC ECSTDY ECENDY);
m = input(transtrn(ECTRT,"MODULE", trimn('')), 8.);
module = put(m, z2.);
if ECMOOD = "PERFORMED" then output;
run;
proc sort data = ec_to_adsl;
by USUBJID m;
run;
proc transpose data = ec_to_adsl out = widetrtp(drop = _name_) prefix = TRT suffix = P;
    by USUBJID ;
    id module;
    var ECTRT;
run;
proc transpose data = ec_to_adsl out = widedosea(drop = _name_) prefix = DOSE suffix = A;
    by USUBJID ;
    id module;
    var ECDOSE;
run;
proc transpose data = ec_to_adsl out = widedoseu(drop = _name_) prefix = DOSE suffix = U;
    by USUBJID ;
    id module;
    var ECDOSU;
run;
data widedosep;
set widedosea(keep = USUBJID);
DOSE01P = 40;
DOSE02P = 40;
DOSE03P = 40;
DOSE04P = 40;
DOSE05P = 40;
DOSE06P = 40;
DOSE07P = 40;
run;
data ec_to_adsl2;
set ec_to_adsl;
if ECDOSE ^=. then output;
run;
proc transpose data = ec_to_adsl2 out = widetrta(drop = _name_) prefix = TRT suffix = A;
    by USUBJID ;
    id module;
    var ECTRT;
run;
proc transpose data = ec_to_adsl2 out = widetrsdt(drop = _name_) prefix = TR suffix = SDT;
    by USUBJID ;
    id module;
    var ECSTDTC;
run;
proc transpose data = ec_to_adsl2 out = widetredt(drop = _name_) prefix = TR suffix = EDT;
    by USUBJID ;
    id module;
    var ECENDTC;
run;
data ADSL;
merge ADSL widetrtp widetrta widedosep widedosea widedoseu widetrsdt widetredt;
by USUBJID;
run;
/*SAFFL flag: Identify which patients completed at least one CBT4CBT module*/
proc sql;
create table ids as 
select USUBJID, count(*) as n_id
from EX
group by USUBJID;
quit;
data ADSL;
merge ADSL ids(in = want);
by USUBJID;
if want then SAFFL = "Y";
	if SAFFL = "" then SAFFL = "N";
if want then FASFL = "Y";
	if FASFL = "" then FASFL = "N";
if n_id = 7 then PPROTFL = "Y";
	else if n_id < 7 then PPROTFL = "N";
drop n_id;
run;

/*Include randomization dates from DS */
data rands;
set DS (keep = USUBJID DSSTDTC);
run;
data ADSL;
merge ADSL rands;
by USUBJID;
RANDDT = DSSTDTC;
drop DSSTDTC;
run;

/*Include stratification factors*/
data strata1;
set MH (keep = USUBJID MHTERM MHDECOD MHOCCUR);
STRAT1D = MHTERM;
STRAT1R = MHOCCUR;
if (MHDECOD = "CURRENT") then output strata1;
keep USUBJID STRAT1D STRAT1R;
run;
data strata2;
set MH (keep = USUBJID MHTERM MHDECOD MHOCCUR);
STRAT2D = MHTERM;
STRAT2R = MHOCCUR;
if (MHDECOD = "PRIMARY") then output strata2;
keep USUBJID STRAT2D STRAT2R;
run;
data ADSL;
merge ADSL strata1 strata2;
by USUBJID;
STRATAR = catx(", ", STRAT1R, STRAT2R);
if STRAT1R = "Y" and STRAT2R = "Y" then STRATARN = 1;
	else if STRAT1R = "Y" and STRAT2R = "N" then STRATARN = 2;
	else if STRAT1R = "N" and STRAT2R = "Y" then STRATARN = 3;
	else if STRAT1R = "N" and STRAT2R = "N" then STRATARN = 4;
run;



/*Create ADSU (Analysis Data Substance Use) ADaM BDS (Basic Data Structure data set)*/;

/*Combine SU and SUPPSU datasets*/
data _ssu;
set SUPPSU;
if IDVAR = "SUSEQ" then SUSEQ = IDVARVAL;
run;
proc transpose data = _ssu out = _ssu;
by USUBJID SUSEQ;
id QNAM;
idlabel QLABEL;
var QVAL;
run;
data _ssu;
merge SU _ssu;
by USUBJID SUSEQ;
drop _name_;
run;

/*Select columns from SU*/
data ADSU;
length PARAM $200 PARAMCD $8 AVALC $200;
set _ssu(keep = USUBJID SUSEQ SUTRT SUCAT SUDOSE SUSTDTC SUENDTC 
			  SUSTDY SUENDY SUDW SUHD);
PARAM = SUTRT;
PARAMCD = SUCAT;
ASTDT = SUSTDTC;
AENDT = SUENDTC;
ASTDY = SUSTDY;
AENDY = SUENDY;

if ASTDY > 0 then ALSTDY = log(ASTDY);

AVAL = SUDOSE;
	if AVAL = . then AVALC = "U";
	else if AVAL = 0 then AVALC = "N";
	else if AVAL = 1 then AVALC = "Y";

run;

/*Merge SU dates and ADSL data*/
data ADSU;
merge ADSL ADSU;
by USUBJID;
run;

/*Create planned and actual treatment column (TRTA) to identify days when modules
were delivered and the 6 days immediately after or until next module was delivered*/
data ADSU;
set ADSU;
t1 = min(intnx('day', input(TR01SDT,yymmdd10.), 6), input(TR02SDT,yymmdd10.));
t2 = min(intnx('day', input(TR02SDT,yymmdd10.), 6), input(TR03SDT,yymmdd10.));
t3 = min(intnx('day', input(TR03SDT,yymmdd10.), 6), input(TR04SDT,yymmdd10.));
t4 = min(intnx('day', input(TR04SDT,yymmdd10.), 6), input(TR05SDT,yymmdd10.));
t5 = min(intnx('day', input(TR05SDT,yymmdd10.), 6), input(TR06SDT,yymmdd10.));
t6 = min(intnx('day', input(TR06SDT,yymmdd10.), 6), input(TR07SDT,yymmdd10.));
t7 = intnx('day', input(TR07SDT,yymmdd10.), 6);
format t1 t2 t3 t4 t5 t6 t7 yymmdd10.;
run;
data ADSU;
set ADSU;
length TRTA $40;
t1_adjust = put(t1, yymmdd10.);
t2_adjust = put(t2, yymmdd10.);
t3_adjust = put(t3, yymmdd10.);
t4_adjust = put(t4, yymmdd10.);
t5_adjust = put(t5, yymmdd10.);
t6_adjust = put(t6, yymmdd10.);
t7_adjust = put(t7, yymmdd10.);

if TR01SDT <= ASTDT <= t1_adjust then TRTA = TRT01A;
if TR02SDT <= ASTDT <= t2_adjust then TRTA = TRT02A;
if TR03SDT <= ASTDT <= t3_adjust then TRTA = TRT03A;
if TR04SDT <= ASTDT <= t4_adjust then TRTA = TRT04A;
if TR05SDT <= ASTDT <= t5_adjust then TRTA = TRT05A;
if TR06SDT <= ASTDT <= t6_adjust then TRTA = TRT06A;
if TR07SDT <= ASTDT <= t7_adjust then TRTA = TRT07A;

run;


/*If more than one module occurred on the same day, then flag that day and 6 days after */
%macro multi_mods(ds = , modn = , modnc = );
data &ds;
set &ds;
length CRIT1 $200;
if TRTA in ("MODULE &modn", "MODULE &modnc") and 
	TR0&modn.SDT ^= "" and 
	TR0&modn.SDT = TR0&modnc.SDT then CRIT1 = "On a day when multiple treatment modules were completed or within 6 days after";
run;
%mend multi_mods;

%multi_mods(ds = ADSU, modn = 1, modnc = 2);
%multi_mods(ds = ADSU, modn = 2, modnc = 3);
%multi_mods(ds = ADSU, modn = 3, modnc = 4);
%multi_mods(ds = ADSU, modn = 4, modnc = 5);
%multi_mods(ds = ADSU, modn = 5, modnc = 6);
%multi_mods(ds = ADSU, modn = 6, modnc = 7);

/*Flag which days are on or within 6 days after only one module was completed*/
data ADSU;
set ADSU;
length CRIT1FL $2 CRIT2 $200 CRIT2FL $2 CRIT3 $200 CRIT3FL $2 PPROTRFL $2;

if CRIT1 ^= "" then CRIT1FL = "Y";
 else CRIT1FL = "N";

if TRTA ^= "" and CRIT1FL = "N" then 
	CRIT2 = "On a day when only one treatment module was completed or within 6 days after";

if CRIT2 ^= "" then CRIT2FL = "Y";
	else CRIT2FL = "N";

if CRIT2FL = "Y" and STRAT1R = "Y" then PPROTRFL = "Y";

CRIT3 = "A high-risk drinking day (Fri, Sat, Sun, Holiday, or Holiday Eve)";

if prxmatch("/Friday|Saturday|Sunday/i", SUDW) or SUHD ^= "" then CRIT3FL = "Y";
	else CRIT3FL = "N";
run;


/*Identify days 7 days immediately before module was completed or until previous module was delivered*/
data ADSU;
set ADSU;
t1 = intnx('day', input(TR01SDT,yymmdd10.), -7);
t2 = intnx('day', input(TR02SDT,yymmdd10.), -7);
t3 = intnx('day', input(TR03SDT,yymmdd10.), -7);
t4 = intnx('day', input(TR04SDT,yymmdd10.), -7);
t5 = intnx('day', input(TR05SDT,yymmdd10.), -7);
t6 = intnx('day', input(TR06SDT,yymmdd10.), -7);
t7 = intnx('day', input(TR07SDT,yymmdd10.), -7);
format t1 t2 t3 t4 t5 t6 t7 yymmdd10.;
run;
data ADSU;
set ADSU;
t1_adjust = put(t1, yymmdd10.);
t2_adjust = put(t2, yymmdd10.);
t3_adjust = put(t3, yymmdd10.);
t4_adjust = put(t4, yymmdd10.);
t5_adjust = put(t5, yymmdd10.);
t6_adjust = put(t6, yymmdd10.);
t7_adjust = put(t7, yymmdd10.);

if TR01SDT > ASTDT >= t1_adjust then mod = TRT01A;
if TR02SDT > ASTDT >= t2_adjust then mod = TRT02A;
if TR03SDT > ASTDT >= t3_adjust then mod = TRT03A;
if TR04SDT > ASTDT >= t4_adjust then mod = TRT04A;
if TR05SDT > ASTDT >= t5_adjust then mod = TRT05A;
if TR06SDT > ASTDT >= t6_adjust then mod = TRT06A;
if TR07SDT > ASTDT >= t7_adjust then mod = TRT07A;


if TR01SDT > ASTDT >= t1_adjust then previous_drinking = AVAL;
if TR02SDT > ASTDT >= t2_adjust then previous_drinking = AVAL;
if TR03SDT > ASTDT >= t3_adjust then previous_drinking = AVAL;
if TR04SDT > ASTDT >= t4_adjust then previous_drinking = AVAL;
if TR05SDT > ASTDT >= t5_adjust then previous_drinking = AVAL;
if TR06SDT > ASTDT >= t6_adjust then previous_drinking = AVAL;
if TR07SDT > ASTDT >= t7_adjust then previous_drinking = AVAL;

run;
proc means data = ADSU noprint nway;
class USUBJID mod;
var previous_drinking;
output out = previous_drinking mean = m;
run;

data previous_drinking;
set previous_drinking(keep = USUBJID mod m);
if m > 0 then ALWD = "Y";
	else if m ^> 0 then ALWD = "N";
length TRTA $40;
TRTA = mod;
drop m mod;
run;
proc sort data = ADSU;
by USUBJID TRTA;
run;
proc sort data = previous_drinking;
by USUBJID TRTA;
run;
data ADSU;
merge ADSU previous_drinking;
by USUBJID TRTA;
if STUDYID ^= "" then output;
run;
proc sort data = ADSU;
by USUBJID ASTDT;
run;

data _qsasi;
set QS(keep = USUBJID QSTESTCD QSSTRESN);
AASIALC = QSSTRESN;
where QSTESTCD in ("ASIALC");
drop QSTESTCD QSSTRESN;
run;
data ADSU;
merge ADSU _qsasi;
by USUBJID;
run;

data _qbsi;
set QS(keep = USUBJID QSDTC QSTESTCD QSSTRESN);
length ASTDT $40;
ABSI = QSSTRESN;
ASTDT = put(QSDTC, yymmdd10.);
where QSTESTCD in ("BSI53_M");
drop QSTESTCD QSDTC QSSTRESN;
run;


data ADSU;
merge ADSU(in = a) _qbsi;
by USUBJID ASTDT;
if a then output;
run;

data ADSU;
set ADSU;
by USUBJID;

if first.USUBJID then bsi = ABSI;
else bsi = coalesce(ABSI, bsi);
retain bsi;

ABSI = bsi;
drop bsi;
run;

/*Select columns to create ADSU*/
%let adsucols = STUDYID SITEID USUBJID SUSEQ TRTA PARAM PARAMCD AVAL AVALC 
	 ASTDT AENDT ASTDY ALSTDY AENDY CRIT1 CRIT1FL CRIT2 CRIT2FL CRIT3 CRIT3FL 
	 SUDW SUHD ALWD ABSI AASIALC SEX AGE AAGE FASFL PPROTFL STRATAR STRATARN 
	 STRAT1D STRAT1R STRAT2D STRAT2R PPROTRFL;

data ADSU;
retain &adsucols.; 
set ADSU(keep = &adsucols.);
run;



/*ANALYSES*/;

/*Descriptive statistics and plots*/;
 proc means data = ADSU missing maxdec = 2;
 class TRTA;
 var AVAL;
 where PPROTRFL = "Y";
 run;
 proc means data = ADSU missing maxdec = 2;
 class SUDW;
 var AVAL;
 where PPROTRFL = "Y";
 run;
 proc means data = ADSU missing maxdec = 2;
 class SUHD;
 var AVAL;
 where PPROTRFL = "Y";
 run;
 proc means data = ADSU missing maxdec = 2;
 class CRIT3FL;
 var AVAL;
 where PPROTRFL = "Y";
 run;
 proc means data = ADSU missing maxdec = 2;
 class ALWD;
 var AVAL;
 where PPROTRFL = "Y";
 run;

 proc means data = ADSU noprint maxdec = 2;
 class ASTDY;
 var AVAL;
 where PPROTRFL = "Y";
 output out = bubble n= mean= / autoname;
 run;
 proc sgplot data = bubble(where = (ASTDY ^= .));
   bubble x = ASTDY y = AVAL_mean size = AVAL_n;
 run;
 proc means data = ADSU noprint maxdec = 2;
 class ALSTDY;
 var AVAL;
 where PPROTRFL = "Y";
 output out = bubble n= mean= / autoname;
 run;
 proc sgplot data = bubble(where = (ALSTDY ^= .));
   bubble x = ALSTDY y = AVAL_mean size = AVAL_n;
 run;
 proc means data = ADSU noprint maxdec = 2;
 class AGE;
 var AVAL;
 where PPROTRFL = "Y";
 output out = bubble n= mean= / autoname;
 run;
 proc sgplot data = bubble(where = (AGE ^= .));
   bubble x = AGE y = AVAL_mean size = AVAL_n;
 run;
 proc means data = ADSU noprint maxdec = 2;
 class AAGE;
 var AVAL;
 where PPROTRFL = "Y";
 output out = bubble n= mean= / autoname;
 run;
 proc sgplot data = bubble(where = (AAGE ^= .));
   bubble x = AAGE y = AVAL_mean size = AVAL_n;
 run;
 proc means data = ADSU noprint maxdec = 2;
 class AASIALC;
 var AVAL;
 where PPROTRFL = "Y";
 output out = bubble n= mean= / autoname;
 run;
 proc sgplot data = bubble(where = (AASIALC ^= .));
   bubble x = AASIALC y = AVAL_mean size = AVAL_n;
 run;
 proc means data = ADSU noprint maxdec = 2;
 class ABSI;
 var AVAL;
 where PPROTRFL = "Y";
 output out = bubble n= mean= / autoname;
 run;
 proc sgplot data = bubble(where = (ABSI ^= .));
   bubble x = ABSI y = AVAL_mean size = AVAL_n;
 run;




 /* Bayesian MLM with informative priors */;
%let tm = TRTA_MODULE;
data prior;
input _type_ $ intercept ALSTDY SEX_F AAGE AASIALC ABSI ALWD_Y CRIT3FL_Y
			   &tm._1 &tm._2 &tm._3 &tm._4 &tm._5 &tm._6 &tm._7
			   &tm._1_CRIT3FL_Y &tm._2_CRIT3FL_Y &tm._3_CRIT3FL_Y 
			   &tm._4_CRIT3FL_Y &tm._5_CRIT3FL_Y &tm._6_CRIT3FL_Y 
			   &tm._7_CRIT3FL_Y;
 datalines;
mean 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
 var 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
;
run;
proc bglimm data = ADSU
nbi = 100 nmc = 100000 thin = 25 nthreads = 4 seed = 1
outpost = post DIC missing = completecase;
class USUBJID SEX(ref = "M") ALWD(ref = "N") TRTA CRIT3FL(ref = "N");
model AVAL(event = "1") = ALSTDY SEX AAGE AAGE AASIALC ABSI ALWD 
	TRTA CRIT3FL TRTA*CRIT3FL / 
	dist = binary link = logit cprior = normal(input = prior);
random intercept ASTDY / sub = USUBJID type = vc nooutpost;
where PPROTRFL = "Y";
/*where PPROTRFL = "Y" and PPROTFL = "Y";*/
options validvarname=v7;
run;


/* Posterior probability comparing slopes and individual timepoints*/;

%macro probs(in = , out = , mod1 = , mod2 = );

%if &mod1. = 7 %then %do;
data &out.;
set &in.;
low_pm&mod1.&mod2. = (TRTA_MODULE_&mod2. < 0);
low_pm&mod2.&mod1. = 1 - low_pm&mod1.&mod2.;
high_pm&mod1.&mod2. = (TRTA_MODULE_&mod2. + CRIT3FL_Y + TRTA_MODULE_&mod2._CRIT3FL_Y < 0 + CRIT3FL_Y);
high_pm&mod2.&mod1. = 1 - high_pm&mod1.&mod2.;
run;
%end;

%else %if &mod2. = 7 %then %do;
data &out.;
set &in.;
low_pm&mod1.&mod2. = (TRTA_MODULE_&mod1. > 0);
low_pm&mod2.&mod1. = 1 - low_pm&mod1.&mod2.;
high_pm&mod1.&mod2. = (TRTA_MODULE_&mod1. + CRIT3FL_Y + TRTA_MODULE_&mod1._CRIT3FL_Y > 0 + CRIT3FL_Y);
high_pm&mod2.&mod1. = 1 - high_pm&mod1.&mod2.;
run;
%end;

%else %do;
data &out.;
set &in.;
low_pm&mod1.&mod2. = (TRTA_MODULE_&mod2. < TRTA_MODULE_&mod1.);
low_pm&mod2.&mod1. = 1 - low_pm&mod1.&mod2.;
high_pm&mod1.&mod2. = (TRTA_MODULE_&mod2. + CRIT3FL_Y + TRTA_MODULE_&mod2._CRIT3FL_Y < TRTA_MODULE_&mod1. + CRIT3FL_Y + TRTA_MODULE_&mod1._CRIT3FL_Y);
high_pm&mod2.&mod1. = 1 - high_pm&mod1.&mod2.;
run;
%end;

%mend probs;

%probs(in = post, out = prob, mod1 = 1, mod2 = 7);
%probs(in = prob, out = prob, mod1 = 1, mod2 = 6);
%probs(in = prob, out = prob, mod1 = 1, mod2 = 5);
%probs(in = prob, out = prob, mod1 = 1, mod2 = 4);
%probs(in = prob, out = prob, mod1 = 1, mod2 = 3);
%probs(in = prob, out = prob, mod1 = 1, mod2 = 2);
%probs(in = prob, out = prob, mod1 = 2, mod2 = 7);
%probs(in = prob, out = prob, mod1 = 2, mod2 = 6);
%probs(in = prob, out = prob, mod1 = 2, mod2 = 5);
%probs(in = prob, out = prob, mod1 = 2, mod2 = 4);
%probs(in = prob, out = prob, mod1 = 2, mod2 = 3);
%probs(in = prob, out = prob, mod1 = 3, mod2 = 7);
%probs(in = prob, out = prob, mod1 = 3, mod2 = 6);
%probs(in = prob, out = prob, mod1 = 3, mod2 = 5);
%probs(in = prob, out = prob, mod1 = 3, mod2 = 4);
%probs(in = prob, out = prob, mod1 = 4, mod2 = 7);
%probs(in = prob, out = prob, mod1 = 4, mod2 = 6);
%probs(in = prob, out = prob, mod1 = 4, mod2 = 5);
%probs(in = prob, out = prob, mod1 = 5, mod2 = 7);
%probs(in = prob, out = prob, mod1 = 5, mod2 = 6);
%probs(in = prob, out = prob, mod1 = 6, mod2 = 7);

proc means data = prob mean maxdec = 2 noprint;
var low_: high_:;
output out = probs_pm mean = / autoname;
run;
proc transpose data = probs_pm(drop = _type_ _freq_) out = probs_pm;
run;
data probs_pm;
set probs_pm;
p = col1;
if p > 0.975 then detection = "Y";
drop col1;
run;
proc sort data = probs_pm;
by descending p;
run;
proc print data = probs_pm;
format p 9.3;
run;


/*Plot medians and 95% credibility intervals (equal-tailed)*/;
/*Source example: http://biometry.github.io/APES//LectureNotes/StatsCafe/Linear_models_jags.html*/

%macro plot_probs(in = , out = , mod = );

%if &mod. = 7 %then %do; 
data &out.;
set &in.;
low_logodds_m&mod. = intercept;
low_prob_m&mod. = logistic(low_logodds_m&mod.);
high_logodds_m&mod. = intercept + CRIT3FL_Y;
high_prob_m&mod. = logistic(high_logodds_m&mod.);
run;
%end;

%else %do;
data &out.;
set &in.;
low_logodds_m&mod. = intercept + TRTA_MODULE_&mod.;
low_prob_m&mod. = logistic(low_logodds_m&mod.);
high_logodds_m&mod. = intercept + TRTA_MODULE_&mod. + CRIT3FL_Y + TRTA_MODULE_&mod._CRIT3FL_Y;
high_prob_m&mod. = logistic(high_logodds_m&mod.);
run;
%end;

%mend plot_probs;

%plot_probs(in = post, out = p, mod = 1);
%plot_probs(in = p, out = p, mod = 2);
%plot_probs(in = p, out = p, mod = 3);
%plot_probs(in = p, out = p, mod = 4);
%plot_probs(in = p, out = p, mod = 5);
%plot_probs(in = p, out = p, mod = 6);
%plot_probs(in = p, out = p, mod = 7);


/* Posterior means, medians, 95% credibility intervals (epual-tailed ETI)*/;
%macro post_m_95ci(post = , param = );

proc means data = &post. noprint nolabels;
/*by simulation;*/
var &param.;
output out = means(drop = _type_ _freq_) mean= means / noinherit;
run;

proc freq data = &post. noprint;
/*by simulation;*/
tables &param. / out = ci outcum nofreq;
run;

proc sql;
create table ci_lower as
	select min(&param.) as ci_lower from ci 
	where cum_pct >= 2.5;
/*	group by simulation;*/
create table medians as
	select min(&param.) as medians from ci 
	where cum_pct >= 50;
/*	group by simulation;*/
create table ci_upper as
	select min(&param.) as ci_upper from ci 
	where cum_pct >= 97.5;
/*	group by simulation;*/
quit;

data post_&param.; 
merge means ci_lower medians ci_upper; 
length parameter $ 50;
parameter = "&param.";
/*by simulation;*/
run;

%mend post_m_95ci;

%post_m_95ci(post = p, param = low_prob_m1);
%post_m_95ci(post = p, param = low_prob_m2);
%post_m_95ci(post = p, param = low_prob_m3);
%post_m_95ci(post = p, param = low_prob_m4);
%post_m_95ci(post = p, param = low_prob_m5);
%post_m_95ci(post = p, param = low_prob_m6);
%post_m_95ci(post = p, param = low_prob_m7);
%post_m_95ci(post = p, param = high_prob_m1);
%post_m_95ci(post = p, param = high_prob_m2);
%post_m_95ci(post = p, param = high_prob_m3);
%post_m_95ci(post = p, param = high_prob_m4);
%post_m_95ci(post = p, param = high_prob_m5);
%post_m_95ci(post = p, param = high_prob_m6);
%post_m_95ci(post = p, param = high_prob_m7);

%post_m_95ci(post = p, param = low_logodds_m1);
%post_m_95ci(post = p, param = low_logodds_m2);
%post_m_95ci(post = p, param = low_logodds_m3);
%post_m_95ci(post = p, param = low_logodds_m4);
%post_m_95ci(post = p, param = low_logodds_m5);
%post_m_95ci(post = p, param = low_logodds_m6);
%post_m_95ci(post = p, param = low_logodds_m7);
%post_m_95ci(post = p, param = high_logodds_m1);
%post_m_95ci(post = p, param = high_logodds_m2);
%post_m_95ci(post = p, param = high_logodds_m3);
%post_m_95ci(post = p, param = high_logodds_m4);
%post_m_95ci(post = p, param = high_logodds_m5);
%post_m_95ci(post = p, param = high_logodds_m6);
%post_m_95ci(post = p, param = high_logodds_m7);


data coeffs; 
set post_low_prob_m1 
	post_low_prob_m2
	post_low_prob_m3
	post_low_prob_m4
	post_low_prob_m5
	post_low_prob_m6
	post_low_prob_m7
	post_high_prob_m1
	post_high_prob_m2
	post_high_prob_m3
	post_high_prob_m4
	post_high_prob_m5
	post_high_prob_m6
	post_high_prob_m7
	post_low_logodds_m1 
	post_low_logodds_m2
	post_low_logodds_m3
	post_low_logodds_m4
	post_low_logodds_m5
	post_low_logodds_m6
	post_low_logodds_m7
	post_high_logodds_m1
	post_high_logodds_m2
	post_high_logodds_m3
	post_high_logodds_m4
	post_high_logodds_m5
	post_high_logodds_m6
	post_high_logodds_m7;

Module = prxchange('s/low_prob_m|high_prob_m|low_logodds_m|high_logodds_m//i', -1, parameter);
length Day paramgroup $15;
if prxmatch("/low/i", parameter) then Day = "Low-risk";
	else if prxmatch("/high/i", parameter) then Day = "High-risk";
Day = trim(Day);
if prxmatch("/prob/i", parameter) then paramgroup = "probability";
	else if prxmatch("/logodds/i", parameter) then paramgroup = "logodds";
paramgroup = trim(paramgroup);

/*format means ci_lower medians ci_upper percent5.;*/
run;

proc sort data = coeffs;
by Day;
run;

proc sgplot data = coeffs noautolegend noborder;
by Day;
vbarparm category = Module response = medians /
   limitlower = ci_lower limitupper = ci_upper;
   xaxis label = "CBT4CBT Module"
   		valueattrs = (size = 17pt) labelattrs = (size = 20pt weight = bold);
   yaxis values = (0 to 1 by 0.25) label = "Probability of Alcohol Use"
   		valueattrs = (size = 17pt) labelattrs = (size = 18pt weight = bold);
where paramgroup = "probability";
format means ci_lower medians ci_upper percent5.;
run;
proc sgplot data = coeffs noautolegend noborder;
by Day;
vbarparm category = Module response = medians /
   limitlower = ci_lower limitupper = ci_upper;
   xaxis label = "CBT4CBT Module"
   		valueattrs = (size = 17pt) labelattrs = (size = 20pt weight = bold);
   yaxis values = (-5 to 5 by 1) label = "Log Odds of Alcohol Use"
   		valueattrs = (size = 17pt) labelattrs = (size = 18pt weight = bold);
where paramgroup = "logodds";
run;
;
