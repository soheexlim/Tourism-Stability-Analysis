clear all
set more off

* Define path
global path "/Users/soheelim/Desktop/Tourism_Stability_Project/Datasets (Raw)/"

********************************************************************************
* 1. Import and preprocess datasets
********************************************************************************
import delimited "$path/GDP, PPP (constant 2021 international $).csv", clear varnames(4) stringcols(1)
drop indicatorname indicatorcode countrycode
keep countryname v5-v68
reshape long v, i(countryname) j(year)
destring year, replace
replace year = year + 1955
rename v gdp_ppp
save gdp.dta, replace

import delimited "$path/Households and NPISHs Final consumption expenditure, PPP (constant 2021 international $).csv", clear varnames(4) stringcols(1)
drop indicatorname indicatorcode countrycode
keep countryname v5-v68
reshape long v, i(countryname) j(year)
destring year, replace
replace year = year + 1955
rename v household_consumption
save consumption.dta, replace

import delimited "$path/International tourism, receipts (current US$).csv", clear varnames(4) stringcols(1)
drop indicatorname indicatorcode countrycode
keep countryname v5-v68
reshape long v, i(countryname) j(year)
destring year, replace
replace year = year + 1955
rename v tourism_receipts
save tourism.dta, replace

import delimited "$path/Inflation, consumer prices (annual %).csv", clear varnames(4) stringcols(1)
drop indicatorname indicatorcode countrycode
keep countryname v5-v68
reshape long v, i(countryname) j(year)
destring year, replace
replace year = year + 1955
rename v inflation
save inflation.dta, replace

import delimited "$path/Official exchange rate (LCU per US$, period average).csv", clear varnames(4) stringcols(1)
drop indicatorname indicatorcode countrycode
keep countryname v5-v68
reshape long v, i(countryname) j(year)
destring year, replace
replace year = year + 1955
rename v exchange_rate
save exchange_rate.dta, replace

import delimited "$path/Unemployment, total (% of total labor force) (modeled ILO estimate).csv", clear varnames(4) stringcols(1)
drop indicatorname indicatorcode countrycode
keep countryname v5-v68
reshape long v, i(countryname) j(year)
destring year, replace
replace year = year + 1955
rename v unemployment
save unemployment.dta, replace

import delimited "$path/Foreign direct investment, net inflows (% of GDP).csv", clear varnames(4) stringcols(1)
drop indicatorname indicatorcode countrycode
keep countryname v5-v68
reshape long v, i(countryname) j(year)
destring year, replace
replace year = year + 1955
rename v fdi
save fdi.dta, replace

import delimited "$path/Political Stability and Absence of Violence, Terrorism.csv", clear varnames(4) stringcols(1)
drop indicatorname indicatorcode countrycode
keep countryname v5-v68
reshape long v, i(countryname) j(year)
destring year, replace
replace year = year + 1955
rename v political_stability
save political_stability.dta, replace

import delimited "$path/International tourism, number of arrivals.csv", clear varnames(4) stringcols(1)
drop indicatorname indicatorcode countrycode
keep countryname v5-v68
reshape long v, i(countryname) j(year)
destring year, replace
replace year = year + 1955
rename v tourism_arrivals
save arrivals.dta, replace

********************************************************************************
* Merge datasets and clean
********************************************************************************
use gdp.dta, clear
merge 1:1 countryname year using consumption.dta, nogenerate
merge 1:1 countryname year using tourism.dta, nogenerate
merge 1:1 countryname year using inflation.dta, nogenerate
merge 1:1 countryname year using exchange_rate.dta, nogenerate
merge 1:1 countryname year using unemployment.dta, nogenerate
merge 1:1 countryname year using fdi.dta, nogenerate
merge 1:1 countryname year using political_stability.dta, nogenerate
merge 1:1 countryname year using arrivals.dta, nogenerate

replace gdp_ppp = gdp_ppp / 1e12
replace household_consumption = household_consumption / 1e12
replace tourism_receipts = tourism_receipts / 1e9
replace tourism_arrivals = tourism_arrivals / 1e6

label variable gdp_ppp "GDP (PPP, Trillions USD)"
label variable household_consumption "Household Consumption (Trillions USD)"
label variable tourism_receipts "Tourism Receipts (Billions USD)"
label variable tourism_arrivals "Tourism Arrivals (Millions)"

drop if year > 2020
drop if year < 1996

egen country_id = group(countryname)
xtset country_id year

* Keep only complete cases for ALL variables used
gen restrict_flag = !missing(tourism_receipts, political_stability, gdp_ppp, inflation, exchange_rate, unemployment, fdi, household_consumption, tourism_arrivals)
keep if restrict_flag == 1

********************************************************************************
* Summary statistics for main variables (full-case sample)
********************************************************************************
summarize tourism_receipts political_stability household_consumption gdp_ppp inflation exchange_rate unemployment fdi tourism_arrivals year country_id restrict_flag
outreg2 using summary_stats.doc, replace sum(log) label word

********************************************************************************
* Create interaction term
********************************************************************************
gen interaction = political_stability * household_consumption

********************************************************************************
* Export each regression model individually and append to the same table (Table 4)
********************************************************************************

* Model 1: Pooled OLS (no interaction)
reg tourism_receipts political_stability gdp_ppp inflation exchange_rate unemployment fdi
outreg2 using reg_results.doc, replace dec(3) label ctitle("Model 1: OLS") word

* Model 2: Fixed Effects (no interaction)
xtreg tourism_receipts political_stability gdp_ppp inflation exchange_rate unemployment fdi, fe
estimates store fe1
outreg2 using reg_results.doc, append dec(3) label ctitle("Model 2: FE") word

* Model 3: Random Effects (no interaction)
xtreg tourism_receipts political_stability gdp_ppp inflation exchange_rate unemployment fdi, re
estimates store re1
outreg2 using reg_results.doc, append dec(3) label ctitle("Model 3: RE") word

hausman fe1 re1

* Model 4: Pooled OLS with interaction
reg tourism_receipts political_stability household_consumption interaction gdp_ppp inflation exchange_rate unemployment fdi
outreg2 using reg_results.doc, append dec(3) label ctitle("Model 4: OLS+Int") word

* Model 5: Fixed Effects with interaction
xtreg tourism_receipts political_stability household_consumption interaction gdp_ppp inflation exchange_rate unemployment fdi, fe
estimates store fe2
outreg2 using reg_results.doc, append dec(3) label ctitle("Model 5: FE+Int") word

* Model 6: Random Effects with interaction
xtreg tourism_receipts political_stability household_consumption interaction gdp_ppp inflation exchange_rate unemployment fdi, re
estimates store re2
outreg2 using reg_results.doc, append dec(3) label ctitle("Model 6: RE+Int") word

hausman fe2 re2

********************************************************************************
* Joint F-test on interaction
********************************************************************************
xtreg tourism_receipts political_stability household_consumption interaction gdp_ppp inflation exchange_rate unemployment fdi, fe
test political_stability interaction

********************************************************************************
* Robustness: use arrivals instead of receipts (Table 4b)
********************************************************************************

* Model A: Pooled OLS with interaction, arrivals as DV
reg tourism_arrivals political_stability household_consumption interaction gdp_ppp inflation exchange_rate unemployment fdi
outreg2 using reg_results_arrivals.doc, replace dec(3) label ctitle("Model A: OLS Arrivals") word

* Model B: Fixed Effects
xtreg tourism_arrivals political_stability household_consumption interaction gdp_ppp inflation exchange_rate unemployment fdi, fe
outreg2 using reg_results_arrivals.doc, append dec(3) label ctitle("Model B: FE Arrivals") word

* Model C: Random Effects
xtreg tourism_arrivals political_stability household_consumption interaction gdp_ppp inflation exchange_rate unemployment fdi, re
outreg2 using reg_results_arrivals.doc, append dec(3) label ctitle("Model C: RE Arrivals") word

********************************************************************************
* Descriptive t-tests by political stability quartile
********************************************************************************
xtile stability_quartile = political_stability, nq(4)
gen stability_q1_or_q4 = .

graph box tourism_receipts, over(stability_quartile, label(angle(0))) title("Tourism Receipts by Political Stability Quartile")
graph box household_consumption, over(stability_quartile, label(angle(0))) title("Household Consumption by Political Stability Quartile")

replace stability_q1_or_q4 = 1 if stability_quartile == 1
replace stability_q1_or_q4 = 2 if stability_quartile == 4
keep if inlist(stability_q1_or_q4, 1, 2)

ttest tourism_receipts, by(stability_q1_or_q4)
ttest household_consumption, by(stability_q1_or_q4)
ttest gdp_ppp, by(stability_q1_or_q4)
ttest inflation, by(stability_q1_or_q4)
ttest exchange_rate, by(stability_q1_or_q4)
ttest unemployment, by(stability_q1_or_q4)
ttest fdi, by(stability_q1_or_q4)

********************************************************************************
* Save final dataset
********************************************************************************
save final_data.dta, replace
