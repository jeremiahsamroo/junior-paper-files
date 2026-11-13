global PATH "C:\Users\jerem\Downloads\JP_files"
collect style cell, font(Courier)
collect style save style-my-dtable, replace
set dtable_style my-dtable
set etable_style my-dtable


use ${PATH}/cps_00004.dta, clear
gen homeownership = (ownershp == 10) if !missing(ownershp)
gen grad = (educ > 111) if educ != 999

/*
 //Get metfips year
preserve

drop if year < 2005

collapse (mean) grad_prop = grad (count) n = grad, by(metfips)

gsort -grad_prop

keep if n >= 5000
gen rank =_n

format grad_prop %9.2f

keep if rank <=30

list metfips grad_prop n rank, sep(0)
list metfips, sep(0)

restore
 
preserve
keep metfips
set seed 548
gen random_order = runiform()
sort random_order
keep in 1/15
list metfips
restore

*/


//gen treatment = inlist(metfips, 47900, 14460, 41940, 15540, 71950, 41860, 10580, 31540, 75700, 12580, 25540, 71650, 73450, 31700, 30460) if !missing(metfips)

gen treatment = inlist(metfips, 47900, 14460, 41940, 15540, 71950, 41860, 10580, 31540, 75700, 12580, 42660, 35620, 39580, 72400, 40380, 25540, 71650, 73450, 31700, 30460)

// random sample gen treatment = inlist(metfips, 35620 33700 77200 12220 7600 16980 16860 17900 640 12420 99998 6200 33100 13460 42660)

//gen treatment = inlist(metfips, 47900, 14460, 41940, 15540, 71950, 41860, 10580, 31540, 75700, 12580)

//gen treatment2 = inlist(metfips, 25540, 71650, 73450, 31700, 30460)

/* validation code



*/

gen post = (year > 2006)
gen treatment_post = treatment*post

gen lngrad = ln(grad)

gen white = (race == 100)
gen black = (race == 200)
gen aapi = (race == 650 | race == 651 | race == 652)
gen other = (race == 300 | race >= 700 & race!= 999)
gen hispanic = (hispan >= 100 & hispan < 900)

gen female = (sex == 2)

gen married = (marst <= 3)

//summarize homeownership grad white black aapi other hispanic female married

/*dtable homeownership grad white black aapi other hispanic female married, by(treatment) title(Descriptive statistics) titlestyles(font(,color(black))) ///
     column(summary(,font(, bold))) halign(center) export(mytable.pdf, replace) nformat(%9.3f)
*/
//table (result) (treatment), stat(mean homeownership grad white black aapi other hispanic female married) ///
//stat(sd homeownership grad white black aapi other hispanic female married)

drop if age < 18
drop if grad == 0
drop if year < 2005

reg homeownership treatment post treatment_post, robust
estimates store reg1
reg homeownership treatment post treatment_post white black aapi hispanic other age married female hhincome, robust
estimates store reg2

etable, estimates (reg1 reg2) showstars stars(.05 "*" .01 "**" 0.001 "***") export (basereg1.pdf, replace)

xtset metfips
gen pre = year - 2007 + 1000
tab year, gen(year_dummy)
reghdfe homeownership i.pre##treatment, absorb(year metfips) vce(cluster metfips)
coefplot, vertical keep(*#*) xline(0) // Plot manually edited

estimates store estudy
etable, estimates(estudy) showstars stars(.05 "*" .01 "**" 0.001 "***") export (estudy.docx, replace)

reghdfe homeownership c.treatment#c.post age female hhinc married white black aapi hispanic other, absorb(year metfips) vce(cluster metfips)
estimates store fipcluster2
reghdfe homeownership c.treatment#c.post, absorb(year metfips) vce(cluster statefip)
estimates store statecluster1

reghdfe homeownership c.treatment#c.post, absorb(year metfips) vce(cluster metfips)
estimates store fipcluster1
reghdfe homeownership c.treatment#c.post age female hhinc married white black aapi hispanic other, absorb(year metfips) vce(cluster statefip)
estimates store statecluster2

etable, estimates (fipcluster1 statecluster1 fipcluster2  statecluster2 ) showstars stars(.05 "*" .01 "**" 0.001 "***") export (robustcheck.docx, replace)
