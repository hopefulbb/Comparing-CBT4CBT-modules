
/*Main Outcome: Daily drinking within 7 days after each CBT4CBT module*/;
/*Main Predictors: CBT4CBT module theme and high-risk drinking day*/;

/* Import ADSL file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/ADaM/ADSL.xlsx'
dbms = xlsx out = ADSL replace;
getnames = yes;
options validvarname = v7;
run;
/* Import ADSU file*/;
proc import datafile = 'C:/Users/bbeni/OneDrive/Documents/Yale/NIAAA K99.R00 MOSAIC/Aim 1/Data/ADaM/ADSU.xlsx'
dbms = xlsx out = ADSU replace;
getnames = yes;
options validvarname = v7;
run;


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
%p
robs(in = prob, out = prob, mod1 = 1, mod2 = 2);
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
