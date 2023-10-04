/*Create CDISC ADaM domain datasets*/;

/* Import DM file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/DM.xlsx'
dbms = xlsx out = DM replace;
getnames = yes;
options validvarname = v7;
run;
/* Import EC file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/EC.xlsx'
dbms = xlsx out = EC replace;
getnames = yes;
options validvarname = v7;
run;
/* Import EX file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/EX.xlsx'
dbms = xlsx out = EX replace;
getnames = yes;
options validvarname = v7;
run;
/* Import DS file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/DS.xlsx'
dbms = xlsx out = DS replace;
getnames = yes;
options validvarname = v7;
run;
/* Import MH file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/MH.xlsx'
dbms = xlsx out = MH replace;
getnames = yes;
options validvarname = v7;
run;
/* Import SUPPSU file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/SUPPSU.xlsx'
dbms = xlsx out = SUPPSU replace;
getnames = yes;
options validvarname = v7;
run;
/* Import SU file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/SU.xlsx'
dbms = xlsx out = SU replace;
getnames = yes;
options validvarname = v7;
run;
/* Import QS file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/SDTM/QS.xlsx'
dbms = xlsx out = QS replace;
getnames = yes;
options validvarname = v7;
run;



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



/*Export ADaM datasets to Excel files*/;
proc export data = ADSL
    outfile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/ADaM/ADSL.xlsx'
    dbms = xlsx
    replace;
run;
proc export data = ADSU
    outfile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/ADaM/ADSU.xlsx'
    dbms = xlsx
    replace;
run;

