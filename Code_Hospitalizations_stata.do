** Importing the data from the CSV File **
insheet using vaping-ban-panel.csv,  names clear


** First, I am marking out firms which actually received treatment **

sort stateid year
gen group_whichtreated = 0
by stateid: egen treatmentyears = sum(vapingban)
replace group_whichtreated = 1 if treatmentyears>0
drop treatmentyears


** marking out years which belonged in the pre-treatment period **

sort year 
by year: egen treatmentacross = sum(vapingban)
gen pre = 1 if treatmentacross==0
replace pre = 0 if treatmentacross>0
drop treatmentacross

** Labelling **

label variable vapingban 					"Vaping Ban passed"
label variable lunghospitalizations			"Lung Hospitalizations"
label variable pre							"Pre-treatment period"
label variable group_whichtreated 			"Treatment Group"

** First, I test for the pre-trends being the same **
** Using year as a continuous variable (to get the slope, i.e., trend), I show that the trend is indeed the same for those which underwent treatment and those which didn't **

** Interaction term: This to see if the group which underwent treatment later has any different pre-trend or not **

gen groupwhichtreated_year_int = year * group_whichtreated 
label variable groupwhichtreated_year_int 	"Treatment Group x Year"

** Regression to estimate pre-trend: Also, restricted sample to pre-treatment period **
reg lunghospitalizations year group_whichtreated groupwhichtreated_year_int if pre==1
eststo regression1
quietly estadd local fixedstate "No", replace
quietly estadd local fixedyear "No", replace


** This is to make the canonical line graph for DiD showing the pre-trends and the treatment effect **

reg lunghospitalizations year#group_whichtreated  
margins year#group_whichtreated
marginsplot, xdim(year) xline(2020)

** I export the graph separately and add it to the word file ** 


** Doing the DiD analysis - The vapingban is the differences in differences variable - with the fixed effects added for both year and state ** 

reg lunghospitalizations vapingban i.stateid i.year
eststo regression2
quietly estadd local fixedstate "Yes", replace
quietly estadd local fixedyear "Yes", replace

** Testing if the combined fixed effects for the states are 0 ** 
testparm i.stateid

** Exporting the two regressions to a word document ** 

global tableoptions "bf(%15.2gc) sfmt(%15.2gc) se label noisily noeqlines nonumbers varlabels(_cons Constant, end("" ) nolast)  starlevels(* 0.1 ** 0.05 *** 0.01) replace r2"
esttab regression1 regression2 using Lungcancer_naturalDiD.rtf, $tableoptions drop (*.stateid *.year) s(fixedstate fixedyear, label("Fixed Effects: State" "Fixed Effects: Year"))
