
/*Main Outcomes: Patient-reported ratings on Patient Feedback Form*/;
/*Main Predictor: CBT4CBT module theme*/;

/* Import ADSL file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/ADaM/ADSL.xlsx'
dbms = xlsx out = ADSL replace;
getnames = yes;
options validvarname = v7;
run;
/* Import ADPFF file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/ADaM/ADPFF.xlsx'
dbms = xlsx out = ADPFF replace;
getnames = yes;
options validvarname = v7;
run;


/*Descriptive statistics and plots*/;
 proc means data = ADPFF missing maxdec = 2 mean std;
 class PARAMCD TRTA TRTAN;
 var AVAL;
 where STRATARN = 1;
 run;
 proc means data = ADPFF missing maxdec = 2;
 class PARAMCD SEX;
 var AVAL;
 where STRATARN = 1;
 run;

 proc means data = ADPFF noprint maxdec = 2 nway;
 class PARAMCD ALSTDY;
 var AVAL;
 output out = bubble n= mean= / autoname;
 where STRATARN = 1;
 run;
 data bubble;
 set bubble;
 if PARAMCD ^= "" then output;
 run;
 proc sgplot data = bubble;
 by PARAMCD;
   bubble x = ALSTDY y = AVAL_mean size = AVAL_n;
 run;
 proc means data = ADPFF noprint maxdec = 2 nway;
 class PARAMCD AAGE;
 var AVAL;
 output out = bubble n= mean= / autoname;
 where STRATARN = 1;
 run;
 data bubble;
 set bubble;
 if PARAMCD ^= "" then output;
 run;
 proc sgplot data = bubble;
 by PARAMCD;
   bubble x = AAGE y = AVAL_mean size = AVAL_n;
 run;
 proc means data = ADPFF noprint maxdec = 2 nway;
 class PARAMCD AASIALC;
 var AVAL;
 output out = bubble n= mean= / autoname;
 where STRATARN = 1;
 run;
data bubble;
 set bubble;
 if PARAMCD ^= "" then output;
 run;
 proc sgplot data = bubble;
 by PARAMCD;
   bubble x = AASIALC y = AVAL_mean size = AVAL_n;
 run;



/*Multiple imputation and analyses for continuous outcomes*/;
/*Source: PharmaSUG 2017 - Paper SP01 Multiple Imputation: A Statistical Programming Story*/;
%let outcome = PFF_07;


proc transpose data = ADPFF out = wide_adpff prefix = module;
by USUBJID SEX AAGE AASIALC PARAMCD PARAM STRAT1R STRAT1D;
id TRTAN;
var AVAL;
where PARAMCD = "&outcome." and STRAT1R = "Y";
run;
proc transpose data = ADPFF out = wide_alstdy prefix = time;
by USUBJID;
id TRTAN;
var ALSTDY;
where PARAMCD = "&outcome." and STRAT1R = "Y";
run;
data wide_adpff;
merge wide_adpff(drop = _name_ _label_) wide_alstdy(drop = _name_ _label_);
by USUBJID;
run;
proc format;
value $ missfmt ' ' = "Missing" other = "Not Missing";
value nmissfmt . = "Missing" other = "Not Missing";
run;
ods output onewayfreqs = miss;
proc freq data = wide_adpff;
table _all_ / missing nocum nofreq;
format _numeric_ nmissfmt. _character_ $missfmt.;
run;
data miss;
set miss;
missing = prxmatch("/Not Missing/i", cats(of _all_));
if missing = 0 then output;
run;
proc sql noprint;
select max(percent) into :n_imp from miss;
quit;
proc mi data = wide_adpff out = mi_mods seed = 1 noprint
nimpute = &n_imp.;
class SEX;
fcs regpmm(module1-module7);
var SEX AASIALC module1-module7;
run;
proc mi data = wide_adpff out = mi_times seed = 1 noprint
nimpute = &n_imp.;
class SEX;
fcs regpmm(time1-time7);
var SEX AASIALC time1-time7;
run;
proc transpose data = mi_mods out = mi_mods(rename = (col1 = AVAL));
by _imputation_ USUBJID SEX AAGE AASIALC PARAMCD PARAM STRAT1R STRAT1D;
var module1-module7;
run;
proc transpose data = mi_times out = mi_times(rename = (col1 = ALSTDY));
by _imputation_ USUBJID;
var time1-time7;
run;
data mi_mods;
set mi_mods;
length TRTAN $1;
TRTAN = compress(_name_, , "kd");
run;
data mi_times;
set mi_times;
length TRTAN $1;
TRTAN = compress(_name_, , "kd");
run;
data ADPFFMI;
merge mi_mods(drop = _name_) mi_times(drop = _name_);
by _imputation_ USUBJID TRTAN;
ASTDY = exp(ALSTDY);
run;
proc sort data = ADPFFMI;
by USUBJID TRTAN PARAMCD STRAT1R;
run;
proc sort data = ADPFF;
by USUBJID TRTAN PARAMCD STRAT1R;
run;
data ADPFFMI;
merge ADPFFMI(in = mi) ADPFF(in = observed keep = USUBJID TRTAN PARAMCD STRAT1R);
by USUBJID TRTAN PARAMCD STRAT1R;
if mi and not observed then DTYPE = "MI";
where PARAMCD = "&outcome." and STRAT1R = "Y";
run;
proc sort data = ADPFFMI;
by _imputation_ USUBJID TRTAN;
run;
proc means data = adpffmi missing;
class dtype; 
var aval; 
run;



 /* Bayesian MLM with informative priors */;
data prior;
input _type_ $ intercept ALSTDY SEX_F AAGE AASIALC
			   TRTAN_1 TRTAN_2 TRTAN_3 TRTAN_4 TRTAN_5 TRTAN_6 TRTAN_7;
 datalines;
mean 0 0 0 0 0 0 0 0 0 0 0 0
 var 1 1 1 1 1 1 1 1 1 1 1 1
;
run;
ods graphics off;
ods exclude all;
ods noresults;
proc bglimm data = ADPFFMI noprint noclprint
nbi = 100 nmc = 100000 thin = 5 nthreads = 1 seed = 1
outpost = post stats = none diag = none plots = none 
missing = completecase;
by _imputation_;
class USUBJID SEX(ref = "M") TRTAN;
model AVAL = ALSTDY SEX AAGE AASIALC TRTAN  / 
	dist = normal cprior = normal(input = prior);
random intercept ALSTDY / sub = USUBJID type = vc nooutpost;
/*where _imputation_ <= 5;*/
options validvarname=v7;
run;
ods graphics on;
ods exclude none;
ods results;

/* Macro for posterior processing */;
%macro post_by_sim(mac=, data=, sim_var=, var=);

  /* Delete previous results table if it exists */
   proc datasets nolist;
		delete &mac._results; 
	run;
	
  /* Identify number of simulations */
  proc sql noprint;
  	select min(&sim_var.), max(&sim_var.) 
  	into :first, :last
  	from &data.;
  quit;
     
  /*  Loop over each simulation  */
  %do i = &first. %to &last.;
  proc sql noprint;
  	create table subset as 
  	select &sim_var., 
  	%sysfunc(tranwrd(%sysfunc(compbl(&var.)), 
  				%bquote( ), 
  				%bquote(,))) 
  	from &data.
  	where &sim_var. = &i.;
  quit;

  /*  Run autocall macro to generate summary stats  */
 
 %if %lowcase(&mac.) = %bquote(postsum) %then %do; 
  %postsum(data = subset, var = &var., print = no, 
  out = simresults);
  %end;
 %else %if %lowcase(&mac.) = %bquote(postint) %then %do; 
  %postint(data = subset, var = &var., print = no, 
  out = simresults);
  %end;
 %else %if %lowcase(&mac.) = %bquote(sumint) %then %do; 
  %sumint(data = subset, var = &var., print = no, 
  out = simresults);
  %end;
 %else %if %lowcase(&mac.) = %bquote(ess) %then %do; 
  %ess(data = subset, var = &var., print = no, 
  out = simresults);
  %end;
 %else %if %lowcase(&mac.) = %bquote(geweke) %then %do; 
  %geweke(data = subset, var = &var., print = no, 
  out = simresults);
  %end;

  /* Store the summary stats in a table */
 	proc append base = &mac._results
 	data = simresults;
 	run;	
  %end;
  
  proc sort data = &mac._results;
  by parameter;
  run;
  
/*   proc print data = &mac._results; */
/*   by parameter; */
/*   run; */
  
%mend;
/* Check convergence by using the macro to compute summaries by imputation dataset */;
%post_by_sim(mac = ess,	data = post, sim_var = _imputation_, 
	var = intercept ALSTDY TRTAN_1 TRTAN_2 TRTAN_3 TRTAN_4 TRTAN_5 TRTAN_6);
proc means data = ess_results maxdec = 0;
class parameter;
var ess;
run;

/*Posterior summary*/
%sumint(data = post, var = intercept ALSTDY AAGE SEX_F TRTAN_1-TRTAN_6 
		random_vc_1 random_vc_2 scale);

/* Posterior probability comparing slopes and individual timepoints*/;

%macro probs(in = , out = , mod1 = , mod2 = );

%if &mod1. = 7 %then %do;
data &out.;
set &in.;
pm&mod1.&mod2. = (TRTAN_&mod2. < 0);
pm&mod2.&mod1. = 1 - pm&mod1.&mod2.;
run;
%end;

%else %if &mod2. = 7 %then %do;
data &out.;
set &in.;
pm&mod1.&mod2. = (TRTAN_&mod1. > 0);
pm&mod2.&mod1. = 1 - pm&mod1.&mod2.;
run;
%end;

%else %do;
data &out.;
set &in.;
pm&mod1.&mod2. = (TRTAN_&mod2. < TRTAN_&mod1.);
pm&mod2.&mod1. = 1 - pm&mod1.&mod2.;
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
var pm:;
output out = probs_pm mean = / autoname;
run;
proc transpose data = probs_pm(drop = _type_ _freq_) out = probs_pm;
run;
data probs_pm;
set probs_pm;
p = col1;
if p > 0.975 then detection = "Y";
PARAMCD = "&outcome.";
drop col1;
run;
proc sql;
create table outcome as 
select unique PARAMCD, PARAM as Outcome 
from ADPFF 
where prxmatch("/&outcome./i", PARAMCD);
quit;
data probs_pm;
merge probs_pm Outcome;
by PARAMCD;
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
m&mod. = intercept;
run;
%end;

%else %do;
data &out.;
set &in.;
m&mod. = intercept + TRTAN_&mod.;
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
%macro post_m_95ci(in = , out = , param = );

proc means data = &in. noprint nolabels;
/*by simulation;*/
var &param.;
output out = means(drop = _type_ _freq_) mean= means / noinherit;
run;

proc freq data = &in. noprint;
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
create table ci as 
	select * from means, ci_lower, medians, ci_upper;
quit;

data ci;
set ci;
length parameter $ 50;
parameter = "&param.";
/*by simulation;*/
run;

%if %sysfunc(exist(&out.)) %then %do;
		data &out.;
		set &out. ci; 
		by parameter;
		if last.parameter then output;
		run;
    %end;
	%else %do; 
		data &out.;
		set ci; 
		run;
	%end;

%mend post_m_95ci;

%post_m_95ci(in = p, out = post_ci, param = m1);
%post_m_95ci(in = p, out = post_ci, param = m2);
%post_m_95ci(in = p, out = post_ci, param = m3);
%post_m_95ci(in = p, out = post_ci, param = m4);
%post_m_95ci(in = p, out = post_ci, param = m5);
%post_m_95ci(in = p, out = post_ci, param = m6);
%post_m_95ci(in = p, out = post_ci, param = m7);

/*Center estimates around covariate means*/
proc sql noprint;
select mean(AAGE) into :m_aage from ADPFFMI;  
select median(AAGE) into :b_aage from post;
select mean(ALSTDY) into :m_alstdy from ADPFFMI;
select median(ALSTDY) into :b_alstdy from post;
quit;

data coeffs; 
set post_ci;
Module = prxchange('s/m//i', -1, parameter);
PARAMCD = "&outcome.";
mean = means + &m_aage.*&b_aage. + &m_alstdy.*&b_alstdy.;
median = medians + &m_aage.*&b_aage. + &m_alstdy.*&b_alstdy.;
ci_low = ci_lower + &m_aage.*&b_aage. + &m_alstdy.*&b_alstdy.;
ci_high = ci_upper + &m_aage.*&b_aage. + &m_alstdy.*&b_alstdy.;
run;
proc sql;
create table outcome as 
select unique PARAMCD, PARAM as Outcome 
from ADPFF 
where prxmatch("/&outcome./i", PARAMCD);
quit;
data coeffs;
merge coeffs Outcome;
by PARAMCD;
run;
options nobyline;
title height = 15pt #byval(Outcome);
proc sgplot data = coeffs noautolegend noborder;
by Outcome;
vbarparm category = Module response = median /
   limitlower = ci_low limitupper = ci_high;
   xaxis label = "CBT4CBT Module"
   		valueattrs = (size = 17pt) labelattrs = (size = 20pt weight = bold);
   yaxis values = (0 to 4 by 1) label = "Likert Rating"
   		valueattrs = (size = 17pt) labelattrs = (size = 18pt weight = bold);
run;
options byline;
goptions reset = title;














/*Multiple imputation and analyses for binary outcomes*/;
/*Source: PharmaSUG 2017 - Paper SP01 Multiple Imputation: A Statistical Programming Story*/;
%let outcome = PFF_06;


proc transpose data = ADPFF out = wide_adpff prefix = module;
by USUBJID SEX AAGE AASIALC PARAMCD PARAM STRAT1R STRAT1D;
id TRTAN;
var AVAL;
where PARAMCD = "&outcome." and STRAT1R = "Y";
run;
proc transpose data = ADPFF out = wide_alstdy prefix = time;
by USUBJID;
id TRTAN;
var ALSTDY;
where PARAMCD = "&outcome." and STRAT1R = "Y";
run;
data wide_adpff;
merge wide_adpff(drop = _name_ _label_) wide_alstdy(drop = _name_ _label_);
by USUBJID;
run;
proc format;
value $ missfmt ' ' = "Missing" other = "Not Missing";
value nmissfmt . = "Missing" other = "Not Missing";
run;
ods output onewayfreqs = miss;
proc freq data = wide_adpff;
table _all_ / missing nocum nofreq;
format _numeric_ nmissfmt. _character_ $missfmt.;
run;
data miss;
set miss;
missing = prxmatch("/Not Missing/i", cats(of _all_));
if missing = 0 then output;
run;
proc sql noprint;
select max(percent) into :n_imp from miss;
quit;
proc mi data = wide_adpff out = mi_mods seed = 1 noprint
nimpute = &n_imp.;
class SEX;
fcs regpmm(module1-module7);
var SEX AASIALC module1-module7;
run;
proc mi data = wide_adpff out = mi_times seed = 1 noprint
nimpute = &n_imp.;
class SEX;
fcs regpmm(time1-time7);
var SEX AASIALC time1-time7;
run;
proc transpose data = mi_mods out = mi_mods(rename = (col1 = AVAL));
by _imputation_ USUBJID SEX AAGE AASIALC PARAMCD PARAM STRAT1R STRAT1D;
var module1-module7;
run;
proc transpose data = mi_times out = mi_times(rename = (col1 = ALSTDY));
by _imputation_ USUBJID;
var time1-time7;
run;
data mi_mods;
set mi_mods;
length TRTAN $1;
TRTAN = compress(_name_, , "kd");
run;
data mi_times;
set mi_times;
length TRTAN $1;
TRTAN = compress(_name_, , "kd");
run;
data ADPFFMI;
merge mi_mods(drop = _name_) mi_times(drop = _name_);
by _imputation_ USUBJID TRTAN;
ASTDY = exp(ALSTDY);
run;
proc sort data = ADPFFMI;
by USUBJID TRTAN PARAMCD STRAT1R;
run;
proc sort data = ADPFF;
by USUBJID TRTAN PARAMCD STRAT1R;
run;
data ADPFFMI;
merge ADPFFMI(in = mi) ADPFF(in = observed keep = USUBJID TRTAN PARAMCD STRAT1R);
by USUBJID TRTAN PARAMCD STRAT1R;
if mi and not observed then DTYPE = "MI";
where PARAMCD = "&outcome." and STRAT1R = "Y";
run;
proc sort data = ADPFFMI;
by _imputation_ USUBJID TRTAN;
run;
proc means data = adpffmi missing;
class dtype; 
var aval; 
run;

 /* Bayesian MLM with informative priors */;
data prior;
input _type_ $ intercept ALSTDY SEX_F AAGE AASIALC
			   TRTAN_1 TRTAN_2 TRTAN_3 TRTAN_4 TRTAN_5 TRTAN_6 TRTAN_7;
 datalines;
mean 0 0 0 0 0 0 0 0 0 0 0 0
 var 1 1 1 1 1 1 1 1 1 1 1 1
;
run;
ods graphics off;
ods exclude all;
ods noresults;
proc bglimm data = ADPFFMI noprint noclprint
nbi = 100 nmc = 100000 thin = 5 nthreads = 1 seed = 1
outpost = post stats = none diag = none plots = none 
missing = completecase;
by _imputation_;
class USUBJID SEX(ref = "M") TRTAN;
model AVAL(event = "1") = ALSTDY SEX AAGE AASIALC TRTAN  / 
	dist = binary link = logit cprior = normal(input = prior);
random intercept ALSTDY / sub = USUBJID type = vc nooutpost;
/*where _imputation_ <= 5;*/
options validvarname=v7;
run;
ods graphics on;
ods exclude none;
ods results;

/* Macro for posterior processing */;
%macro post_by_sim(mac=, data=, sim_var=, var=);

  /* Delete previous results table if it exists */
   proc datasets nolist;
		delete &mac._results; 
	run;
	
  /* Identify number of simulations */
  proc sql noprint;
  	select min(&sim_var.), max(&sim_var.) 
  	into :first, :last
  	from &data.;
  quit;
     
  /*  Loop over each simulation  */
  %do i = &first. %to &last.;
  proc sql noprint;
  	create table subset as 
  	select &sim_var., 
  	%sysfunc(tranwrd(%sysfunc(compbl(&var.)), 
  				%bquote( ), 
  				%bquote(,))) 
  	from &data.
  	where &sim_var. = &i.;
  quit;

  /*  Run autocall macro to generate summary stats  */
 
 %if %lowcase(&mac.) = %bquote(postsum) %then %do; 
  %postsum(data = subset, var = &var., print = no, 
  out = simresults);
  %end;
 %else %if %lowcase(&mac.) = %bquote(postint) %then %do; 
  %postint(data = subset, var = &var., print = no, 
  out = simresults);
  %end;
 %else %if %lowcase(&mac.) = %bquote(sumint) %then %do; 
  %sumint(data = subset, var = &var., print = no, 
  out = simresults);
  %end;
 %else %if %lowcase(&mac.) = %bquote(ess) %then %do; 
  %ess(data = subset, var = &var., print = no, 
  out = simresults);
  %end;
 %else %if %lowcase(&mac.) = %bquote(geweke) %then %do; 
  %geweke(data = subset, var = &var., print = no, 
  out = simresults);
  %end;

  /* Store the summary stats in a table */
 	proc append base = &mac._results
 	data = simresults;
 	run;	
  %end;
  
  proc sort data = &mac._results;
  by parameter;
  run;
  
/*   proc print data = &mac._results; */
/*   by parameter; */
/*   run; */
  
%mend;
/* Check convergence by using the macro to compute summaries by imputation dataset */;
%post_by_sim(mac = ess,	data = post, sim_var = _imputation_, 
	var = intercept ALSTDY TRTAN_1 TRTAN_2 TRTAN_3 TRTAN_4 TRTAN_5 TRTAN_6);
proc means data = ess_results maxdec = 0;
class parameter;
var ess;
run;

/*Posterior summary*/
%sumint(data = post, var = intercept ALSTDY AAGE SEX_F TRTAN_1-TRTAN_6 
		random_vc_1 random_vc_2 scale);

/* Posterior probability comparing slopes and individual timepoints*/;

%macro probs(in = , out = , mod1 = , mod2 = );

%if &mod1. = 7 %then %do;
data &out.;
set &in.;
pm&mod1.&mod2. = (TRTAN_&mod2. < 0);
pm&mod2.&mod1. = 1 - pm&mod1.&mod2.;
run;
%end;

%else %if &mod2. = 7 %then %do;
data &out.;
set &in.;
pm&mod1.&mod2. = (TRTAN_&mod1. > 0);
pm&mod2.&mod1. = 1 - pm&mod1.&mod2.;
run;
%end;

%else %do;
data &out.;
set &in.;
pm&mod1.&mod2. = (TRTAN_&mod2. < TRTAN_&mod1.);
pm&mod2.&mod1. = 1 - pm&mod1.&mod2.;
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
var pm:;
output out = probs_pm mean = / autoname;
run;
proc transpose data = probs_pm(drop = _type_ _freq_) out = probs_pm;
run;
data probs_pm;
set probs_pm;
p = col1;
if p > 0.975 then detection = "Y";
PARAMCD = "&outcome.";
drop col1;
run;
proc sql;
create table outcome as 
select unique PARAMCD, PARAM as Outcome 
from ADPFF 
where prxmatch("/&outcome./i", PARAMCD);
quit;
data probs_pm;
merge probs_pm Outcome;
by PARAMCD;
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
m&mod. = intercept;
run;
%end;

%else %do;
data &out.;
set &in.;
m&mod. = intercept + TRTAN_&mod.;
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
%macro post_m_95ci(in = , out = , param = );

proc means data = &in. noprint nolabels;
/*by simulation;*/
var &param.;
output out = means(drop = _type_ _freq_) mean= means / noinherit;
run;

proc freq data = &in. noprint;
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
create table ci as 
	select * from means, ci_lower, medians, ci_upper;
quit;

data ci;
set ci;
length parameter $ 50;
parameter = "&param.";
/*by simulation;*/
run;

%if %sysfunc(exist(&out.)) %then %do;
		data &out.;
		set &out. ci; 
		by parameter;
		if last.parameter then output;
		run;
    %end;
	%else %do; 
		data &out.;
		set ci; 
		run;
	%end;

%mend post_m_95ci;

%post_m_95ci(in = p, out = post_ci, param = m1);
%post_m_95ci(in = p, out = post_ci, param = m2);
%post_m_95ci(in = p, out = post_ci, param = m3);
%post_m_95ci(in = p, out = post_ci, param = m4);
%post_m_95ci(in = p, out = post_ci, param = m5);
%post_m_95ci(in = p, out = post_ci, param = m6);
%post_m_95ci(in = p, out = post_ci, param = m7);

/*Center estimates around covariate means*/
proc sql noprint;
select mean(AAGE) into :m_aage from ADPFFMI;  
select median(AAGE) into :b_aage from post;
select mean(ALSTDY) into :m_alstdy from ADPFFMI;
select median(ALSTDY) into :b_alstdy from post;
quit;

data coeffs; 
set post_ci;
Module = prxchange('s/m//i', -1, parameter);
PARAMCD = "&outcome.";
log_mean = means + &m_aage.*&b_aage. + &m_alstdy.*&b_alstdy.;
log_median = medians + &m_aage.*&b_aage. + &m_alstdy.*&b_alstdy.;
log_ci_low = ci_lower + &m_aage.*&b_aage. + &m_alstdy.*&b_alstdy.;
log_ci_high = ci_upper + &m_aage.*&b_aage. + &m_alstdy.*&b_alstdy.;

p_mean = logistic(log_mean);
p_median = logistic(log_median);
p_ci_low = logistic(log_ci_low);
p_ci_high = logistic(log_ci_high);
run;
proc sql;
create table outcome as 
select unique PARAMCD, PARAM as Outcome 
from ADPFF 
where prxmatch("/&outcome./i", PARAMCD);
quit;
data coeffs;
merge coeffs Outcome;
by PARAMCD;
run;
options nobyline;
title height = 15pt #byval(Outcome);
proc sgplot data = coeffs noautolegend noborder;
by Outcome;
vbarparm category = Module response = log_median /
   limitlower = log_ci_low limitupper = log_ci_high;
   xaxis label = "CBT4CBT Module"
   		valueattrs = (size = 17pt) labelattrs = (size = 20pt weight = bold);
   yaxis values = (-5 to 5 by 1) label = "Log Odds"
   		valueattrs = (size = 17pt) labelattrs = (size = 18pt weight = bold);
run;
options byline;
goptions reset = title;

options nobyline;
title height = 15pt #byval(Outcome);
proc sgplot data = coeffs noautolegend noborder;
by Outcome;
vbarparm category = Module response = p_median /
   limitlower = p_ci_low limitupper = p_ci_high;
   xaxis label = "CBT4CBT Module"
   		valueattrs = (size = 17pt) labelattrs = (size = 20pt weight = bold);
   yaxis values = (0 to 1 by 0.25) label = "Probability"
   		valueattrs = (size = 17pt) labelattrs = (size = 18pt weight = bold);
format p_mean p_median p_ci_low p_ci_high percent5.;
run;
options byline;
goptions reset = title;
