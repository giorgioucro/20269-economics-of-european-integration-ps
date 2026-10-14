*===============================================================================
*
*                    Economics of European Integration
*                         Final Report 2025/2026
*
* Course:       20269 - Economics of European Integration
* Institution:  Bocconi University
* Authors:      Tanjima Tasnim, Agnese Porro, Alex Vigna Lobbia,
*               Andrea Boscolo Meneguolo, Giorgio Ucropina
* Date:         March 2026
*
* Purpose:
*   Complete Stata implementation of Problems I-VII. This repository version
*   is portability-adjusted from the definitive collaborative source script;
*   the empirical specifications and computational steps are preserved.
*
* Execution:
*   Start Stata in the repository root, then run: do code_takehome.do
*   Stata 17 or later is required for the final table ... statistic() syntax.
*
* External inputs:
*   See data/README.md. All inputs are read from data/ and are not modified.
*
* User-written commands:
*   outreg2; esttab, eststo, and estadd (estout); prodest; levpet; grc1leg;
*   spmap; shp2dta; ivreg2; ranktest.
*
* Outputs:
*   Generated logs, tables, figures, maps, and intermediate files are written
*   below outputs/. The outputs/ directory is ignored by Git.
*===============================================================================

clear all
set more off
capture log close

local data_dir         "data"
local output_dir       "outputs"
local figure_dir       "outputs/figures"
local map_dir          "outputs/maps"
local table_dir        "outputs/tables"
local intermediate_dir "outputs/intermediate"
local log_dir          "outputs/logs"

capture mkdir "`output_dir'"
capture mkdir "`figure_dir'"
capture mkdir "`map_dir'"
capture mkdir "`table_dir'"
capture mkdir "`intermediate_dir'"
capture mkdir "`log_dir'"

local p1_data          "`data_dir'/EEI_TH_P1_2026.dta"
local employment_data  "`data_dir'/Employment_Shares_Take_Home.dta"
local china_imports    "`data_dir'/Imports_China_Take_Home.dta"
local us_imports       "`data_dir'/Imports_US_China_Take_Home.dta"
local ess_data         "`data_dir'/ESS8e02_3.dta"
local cmp_data         "`data_dir'/MPDataset_MPDS2025a.dta"
local nuts_shp         "`data_dir'/NUTS_RG_20M_2013_3035.shp"

local required_commands ///
    "outreg2 esttab eststo estadd prodest levpet grc1leg spmap shp2dta ivreg2 ranktest"
local missing_command 0
foreach command of local required_commands {
    capture which `command'
    if _rc {
        display as error "Required user-written command is not installed: `command'"
        local missing_command 1
    }
}
if `missing_command' {
    display as error "Install the missing commands documented in README.md, then rerun."
    exit 199
}

capture confirm file "`p1_data'"
if _rc {
    display as error "Required Problem I-V input not found: `p1_data'"
    display as error "See data/README.md and run Stata from the repository root."
    exit 601
}

tempfile p1_clean weights_pre china_region_year us_region_year
tempfile avg_china avg_us regional_shocks us2007
tempfile shock_mapdata manuf_mapdata prob7_shocks ess_france problem7_ab
tempfile problem7_c mp_france problem7_e problem7_f

*******************************************************************************
* PART I - PROBLEMS I-V
*******************************************************************************

log using "`log_dir'/take_home_2026_part1.log", text replace
use "`p1_data'", clear
************************************************************
* Variables for production function estimation
************************************************************

foreach var in real_VA real_sales real_K real_M L {
    gen ln_`var' = .
    replace ln_`var' = ln(`var') if `var' > 0
}
************************************************************
**# Problem I
* 1) Problem I (a): Focus on both countries. Starting from balance-sheet data,
* provide some descriptive statistics (e.g. n. of firms, average capital,
* revenues, number of employees, value added, exporters, FDI) in 2007 comparing
* firms in sector 22 (Publishing, printing and reproduction of recorded media)
* and firms in sector 36 (Manufacture of furniture) for the two countries.
************************************************************
preserve
    keep if year == 2007 & inlist(nace, 22, 36) & inlist(country, "FRA", "ITA")

    ********************************************************
    * TABLE 1: FRANCE - continuous variables
    ********************************************************
    capture erase "`table_dir'/table_problem1_fra.tex"
    file open tfra using "`table_dir'/table_problem1_fra.tex", write text replace

    file write tfra "\begin{table}[htbp]" _n
    file write tfra "\centering" _n
    file write tfra "\caption{Descriptive statistics for France by sector, 2007}" _n
    file write tfra "\label{tab:desc_2007_fra}" _n
    file write tfra "\scriptsize" _n
    file write tfra "\resizebox{\textwidth}{!}{%" _n
    file write tfra "\begin{tabular}{l c rrrr c rrrr}" _n
    file write tfra "\toprule" _n
    file write tfra " & \multicolumn{5}{c}{\textbf{NACE 22: Publishing and printing}} & \multicolumn{5}{c}{\textbf{NACE 36: Furniture}} \\" _n
    file write tfra "\cmidrule(lr){2-6}\cmidrule(lr){7-11}" _n
    file write tfra "Variable & N & Mean & Median & 25th Pct. & 75th Pct. & N & Mean & Median & 25th Pct. & 75th Pct. \\" _n
    file write tfra "\midrule" _n

    local cvars real_sales real_K L real_VA
    local clabs `" "Real revenues (k\euro)" "Real capital (k\euro)" "Employees (L)" "Real value added (k\euro)" "'

    local i = 1
    foreach v of local cvars {
        local lab : word `i' of `clabs'

        quietly summarize `v' if country=="FRA" & nace==22, detail
        local n1   : display %9.0f r(N)
        local m1   : display %9.2f r(mean)
        local p501 : display %9.2f r(p50)
        local p251 : display %9.2f r(p25)
        local p751 : display %9.2f r(p75)

        quietly summarize `v' if country=="FRA" & nace==36, detail
        local n2   : display %9.0f r(N)
        local m2   : display %9.2f r(mean)
        local p502 : display %9.2f r(p50)
        local p252 : display %9.2f r(p25)
        local p752 : display %9.2f r(p75)

        file write tfra "`lab' & `n1' & `m1' & `p501' & `p251' & `p751' & `n2' & `m2' & `p502' & `p252' & `p752' \\" _n
        local ++i
    }

    file write tfra "\bottomrule" _n
    file write tfra "\end{tabular}%" _n
    file write tfra "}" _n
    file write tfra "\end{table}" _n
    file close tfra

    ********************************************************
    * TABLE 2: FRANCE - exporter and FDI counts
    ********************************************************
    capture erase "`table_dir'/table_problem1_fra_status.tex"
    file open tfra2 using "`table_dir'/table_problem1_fra_status.tex", write text replace

    quietly count if country=="FRA" & nace==22
    local n22 = r(N)
    quietly count if country=="FRA" & nace==36
    local n36 = r(N)

    quietly count if country=="FRA" & nace==22 & exporter==1
    local exp22 = r(N)
    quietly count if country=="FRA" & nace==36 & exporter==1
    local exp36 = r(N)

    quietly count if country=="FRA" & nace==22 & FDI==1
    local fdi22 = r(N)
    quietly count if country=="FRA" & nace==36 & FDI==1
    local fdi36 = r(N)

    local expshare22 : display %9.2f (`exp22'/`n22')*100
    local expshare36 : display %9.2f (`exp36'/`n36')*100
    local fdishare22 : display %9.2f (`fdi22'/`n22')*100
    local fdishare36 : display %9.2f (`fdi36'/`n36')*100

    file write tfra2 "\begin{table}[htbp]" _n
    file write tfra2 "\centering" _n
    file write tfra2 "\caption{Exporter and FDI status for France by sector, 2007}" _n
    file write tfra2 "\label{tab:status_2007_fra}" _n
    file write tfra2 "\small" _n
    file write tfra2 "\begin{tabular}{lcc}" _n
    file write tfra2 "\toprule" _n
    file write tfra2 " & \textbf{NACE 22} & \textbf{NACE 36} \\" _n
    file write tfra2 "\midrule" _n
    file write tfra2 "Total firms & `n22' & `n36' \\" _n
    file write tfra2 "Exporters (N) & `exp22' & `exp36' \\" _n
    file write tfra2 "Exporters (\%) & `expshare22' & `expshare36' \\" _n
    file write tfra2 "FDI firms (N) & `fdi22' & `fdi36' \\" _n
    file write tfra2 "FDI firms (\%) & `fdishare22' & `fdishare36' \\" _n
    file write tfra2 "\bottomrule" _n
    file write tfra2 "\end{tabular}" _n
    file write tfra2 "\end{table}" _n
    file close tfra2

    ********************************************************
    * TABLE 3: ITALY - continuous variables
    ********************************************************
    capture erase "`table_dir'/table_problem1_ita.tex"
    file open tita using "`table_dir'/table_problem1_ita.tex", write text replace

    file write tita "\begin{table}[htbp]" _n
    file write tita "\centering" _n
    file write tita "\caption{Descriptive statistics for Italy by sector, 2007}" _n
    file write tita "\label{tab:desc_2007_ita}" _n
    file write tita "\scriptsize" _n
    file write tita "\resizebox{\textwidth}{!}{%" _n
    file write tita "\begin{tabular}{l c rrrr c rrrr}" _n
    file write tita "\toprule" _n
    file write tita " & \multicolumn{5}{c}{\textbf{NACE 22: Publishing and printing}} & \multicolumn{5}{c}{\textbf{NACE 36: Furniture}} \\" _n
    file write tita "\cmidrule(lr){2-6}\cmidrule(lr){7-11}" _n
    file write tita "Variable & N & Mean & Median & 25th Pct. & 75th Pct. & N & Mean & Median & 25th Pct. & 75th Pct. \\" _n
    file write tita "\midrule" _n

    local i = 1
    foreach v of local cvars {
        local lab : word `i' of `clabs'

        quietly summarize `v' if country=="ITA" & nace==22, detail
        local n1   : display %9.0f r(N)
        local m1   : display %9.2f r(mean)
        local p501 : display %9.2f r(p50)
        local p251 : display %9.2f r(p25)
        local p751 : display %9.2f r(p75)

        quietly summarize `v' if country=="ITA" & nace==36, detail
        local n2   : display %9.0f r(N)
        local m2   : display %9.2f r(mean)
        local p502 : display %9.2f r(p50)
        local p252 : display %9.2f r(p25)
        local p752 : display %9.2f r(p75)

        file write tita "`lab' & `n1' & `m1' & `p501' & `p251' & `p751' & `n2' & `m2' & `p502' & `p252' & `p752' \\" _n
        local ++i
    }

    file write tita "\bottomrule" _n
    file write tita "\end{tabular}%" _n
    file write tita "}" _n
    file write tita "\end{table}" _n
    file close tita

    ********************************************************
    * TABLE 4: ITALY - exporter and FDI counts
    ********************************************************
    capture erase "`table_dir'/table_problem1_ita_status.tex"
    file open tita2 using "`table_dir'/table_problem1_ita_status.tex", write text replace

    quietly count if country=="ITA" & nace==22
    local n22 = r(N)
    quietly count if country=="ITA" & nace==36
    local n36 = r(N)

    quietly count if country=="ITA" & nace==22 & exporter==1
    local exp22 = r(N)
    quietly count if country=="ITA" & nace==36 & exporter==1
    local exp36 = r(N)

    quietly count if country=="ITA" & nace==22 & FDI==1
    local fdi22 = r(N)
    quietly count if country=="ITA" & nace==36 & FDI==1
    local fdi36 = r(N)

    local expshare22 : display %9.2f (`exp22'/`n22')*100
    local expshare36 : display %9.2f (`exp36'/`n36')*100
    local fdishare22 : display %9.2f (`fdi22'/`n22')*100
    local fdishare36 : display %9.2f (`fdi36'/`n36')*100

    file write tita2 "\begin{table}[htbp]" _n
    file write tita2 "\centering" _n
    file write tita2 "\caption{Exporter and FDI status for Italy by sector, 2007}" _n
    file write tita2 "\label{tab:status_2007_ita}" _n
    file write tita2 "\small" _n
    file write tita2 "\begin{tabular}{lcc}" _n
    file write tita2 "\toprule" _n
    file write tita2 " & \textbf{NACE 22} & \textbf{NACE 36} \\" _n
    file write tita2 "\midrule" _n
    file write tita2 "Total firms & `n22' & `n36' \\" _n
    file write tita2 "Exporters (N) & `exp22' & `exp36' \\" _n
    file write tita2 "Exporters (\%) & `expshare22' & `expshare36' \\" _n
    file write tita2 "FDI firms (N) & `fdi22' & `fdi36' \\" _n
    file write tita2 "FDI firms (\%) & `fdishare22' & `fdishare36' \\" _n
    file write tita2 "\bottomrule" _n
    file write tita2 "\end{tabular}" _n
    file write tita2 "\end{table}" _n
    file close tita2

restore

*FRA36 has only 16 firms -> Firms in the French furniture sector display much higher mean values of capital, sales, employment, and value added, but this result should be interpreted cautiously because the cell contains only 16 firms and the gap is much smaller at the median.
*Reported sample sizes vary across variables because some balance-sheet items are missing for a subset of firms.

************************************************************
**# Problem II
* 2) Problem II (a): Consider now both countries together.
* Estimate for the two industries available in NACE Rev. 1.1
* 2-digit format the production function coefficients, by
* using standard OLS, the Wooldridge (WRDG) and the
* Levinsohn & Petrin (LP) procedure. How do you treat the fact that data come from different countries in different years in the productivity estimation?
************************************************************

preserve
    keep if nace == 22 | nace == 36

    * Panel declaration
    xtset mark year

    ********************************************************
    * Sector 22
    ********************************************************

    * OLS
    xi: reg ln_real_VA ln_L ln_real_K i.country i.year if nace == 22
    estimates store ols_22


	* WRDG
	xi: prodest ln_real_VA if nace == 22, ///
		met(wrdg) ///
		free(ln_L) ///
		proxy(ln_real_M) ///
		state(ln_real_K) ///
		va
	estimates store wrdg_22

    * LP
	set seed 12345
    xi: levpet ln_real_VA if nace == 22, ///
        free(ln_L i.country i.year) ///
        proxy(ln_real_M) ///
        capital(ln_real_K) ///
        reps(50) level(99) va
    estimates store lp_22

    ********************************************************
    * Sector 36
    ********************************************************

    * OLS
    xi: reg ln_real_VA ln_L ln_real_K i.country i.year if nace == 36
    estimates store ols_36

	* WRDG
	xi: prodest ln_real_VA if nace == 36, ///
		met(wrdg) ///
		free(ln_L) ///
		proxy(ln_real_M) ///
		state(ln_real_K) ///
		va
	estimates store wrdg_36

    * LP
	set seed 67890
    xi: levpet ln_real_VA if nace == 36, ///
        free(ln_L i.country i.year) ///
        proxy(ln_real_M) ///
        capital(ln_real_K) ///
        reps(50) level(99) va
    estimates store lp_36

restore
* Note: levpet uses bootstrap repetitions for the standard errors.
* We set a seed before each LP estimation to make LP standard errors reproducible.

************************************************************
* 2) Problem II (b): Present a Table, where you compare the  coefficients obtained in the estimation
* outputs, indicating their significance levels (*, ** or *** for 10, 5 and 1 per cent).
* Is there any bias of the labour coefficients? What is the reason for that?
************************************************************
label variable ln_L "log(Labour)"
label variable ln_real_K "log(Capital)"

esttab ols_22 wrdg_22 lp_22 ols_36 wrdg_36 lp_36 ///
    using "`table_dir'/table_problem2b_full_controls.tex", replace ///
    b(%9.3f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    mtitles("OLS" "WRDG" "LP" "OLS" "WRDG" "LP") ///
    mgroups("Sector 22" "Sector 36", pattern(1 0 0 1 0 0) span ///
        prefix(\multicolumn{@span}{c}{) suffix(})) ///
    stats(N, fmt(%9.0f) labels("Observations")) ///
    title("Production function estimates by sector and method") ///
    booktabs


esttab ols_22 wrdg_22 lp_22 ols_36 wrdg_36 lp_36 ///
    using "`table_dir'/table_problem2b.tex", replace ///
    b(%9.3f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    mtitles("OLS" "WRDG" "LP" "OLS" "WRDG" "LP") ///
    mgroups("Sector 22" "Sector 36", pattern(1 0 0 1 0 0) span ///
        prefix(\multicolumn{@span}{c}{) suffix(})) ///
    drop(_Icountry* _Iyear* _cons) ///
    stats(N, fmt(%9.0f) labels("Observations")) ///
    title("Production function estimates by sector and method") ///
    booktabs

*=============================================================================
**#								Problem III
*=============================================================================

/* (a) Would there be any difference in estimating the production function using revenues rather than added values in LP, WRDG or OLS? Why is it so? Discuss the issue theoretically, considering the assumptions behind the Cobb-Douglas production function. */

	/* A: See overleaf */


************************************************************
**# Problem IV
* 4) Problem IV (a): Comment on the presence of "extreme" values
* in both industries. Clear the TFP estimates from these extreme
* values (1st and 99th percentiles) and save a "cleaned sample".
* From now on, focus on this sample.
************************************************************

*************************************************
* TFP DEFINITION
*************************************************

*------------------------------------------------
* (i) OLS TFP (kept for completeness)
*------------------------------------------------

* Sector 22
xi: reg ln_real_VA ln_L ln_real_K i.country i.year if nace == 22
predict ln_TFP_OLS_22, residuals
gen TFP_OLS_22 = exp(ln_TFP_OLS_22)

* Sector 36
xi: reg ln_real_VA ln_L ln_real_K i.country i.year if nace == 36
predict ln_TFP_OLS_36, residuals
gen TFP_OLS_36 = exp(ln_TFP_OLS_36)

*------------------------------------------------
* (ii) Wooldridge (WRDG)
*------------------------------------------------

* Sector 22
xi: prodest ln_real_VA if nace == 22, ///
    met(wrdg) ///
    free(ln_L) ///
    proxy(ln_real_M) ///
    state(ln_real_K) ///
    va
predict ln_TFP_WRDG_22, resid
gen TFP_WRDG_22 = exp(ln_TFP_WRDG_22)

* Sector 36
xi: prodest ln_real_VA if nace == 36, ///
    met(wrdg) ///
    free(ln_L) ///
    proxy(ln_real_M) ///
    state(ln_real_K) ///
    va
predict ln_TFP_WRDG_36, resid
gen TFP_WRDG_36 = exp(ln_TFP_WRDG_36)

*------------------------------------------------
* (iii) Levinsohn & Petrin (LP)
*------------------------------------------------

* Sector 22
xi: levpet ln_real_VA if nace == 22, ///
    free(ln_L i.country i.year) ///
    proxy(ln_real_M) ///
    capital(ln_real_K) ///
    reps(20) level(99) va
predict TFP_LP_22, omega

* Sector 36
xi: levpet ln_real_VA if nace == 36, ///
    free(ln_L i.country i.year) ///
    proxy(ln_real_M) ///
    capital(ln_real_K) ///
    reps(20) level(99) va
predict TFP_LP_36, omega

*************************************************
*** Clearing of extreme values
*************************************************

* WRDG estimates
foreach s in 22 36 {
    summarize TFP_WRDG_`s' if nace == `s', detail
    replace TFP_WRDG_`s' = . if !inrange(TFP_WRDG_`s', r(p1), r(p99)) & nace == `s'
}

gen TFP_WRDG = .
replace TFP_WRDG = TFP_WRDG_22 if nace == 22
replace TFP_WRDG = TFP_WRDG_36 if nace == 36
gen ln_TFP_WRDG = ln(TFP_WRDG)

* LP estimates
foreach s in 22 36 {
    summarize TFP_LP_`s' if nace == `s', detail
    replace TFP_LP_`s' = . if !inrange(TFP_LP_`s', r(p1), r(p99)) & nace == `s'
}

gen TFP_LP = .
replace TFP_LP = TFP_LP_22 if nace == 22
replace TFP_LP = TFP_LP_36 if nace == 36
gen ln_TFP_LP = ln(TFP_LP)

* Clean generated dummy variables from xi:
capture drop _Icountry_2 _Iyear_2002 _Iyear_2003 _Iyear_2004 _Iyear_2005 ///
             _Iyear_2006 _Iyear_2007 _Iyear_2008 _Iyear_2009

*************************************************
* GRAPHS USED IN THE LATEX
*************************************************

*------------------------------------------------
* Figure 1: pooled TFP and log-TFP by estimator
*------------------------------------------------
* Package availability was checked in the repository setup block.

twoway ///
    (kdensity TFP_WRDG if nace == 22, lcolor(sienna)) ///
    (kdensity TFP_WRDG if nace == 36, lcolor(black)), ///
    title("TFP Densities with WRDG") ///
    legend(off) ///
    name(wrdg_lev, replace)

twoway ///
    (kdensity ln_TFP_WRDG if nace == 22, lcolor(sienna)) ///
    (kdensity ln_TFP_WRDG if nace == 36, lcolor(black)), ///
    title("Log-TFP Densities with WRDG") ///
    legend(off) ///
    name(wrdg_log, replace)

twoway ///
    (kdensity TFP_LP if nace == 22, lcolor(sienna)) ///
    (kdensity TFP_LP if nace == 36, lcolor(black)), ///
    title("TFP Densities with LP") ///
    legend(off) ///
    name(lp_lev, replace)

twoway ///
    (kdensity ln_TFP_LP if nace == 22, lcolor(sienna)) ///
    (kdensity ln_TFP_LP if nace == 36, lcolor(black)), ///
    title("Log-TFP Densities with LP") ///
    legend(label(1 "Sector 22") label(2 "Sector 36")) ///
    name(lp_log, replace)

grc1leg wrdg_lev wrdg_log lp_lev lp_log, ///
    cols(2) imargin(tiny) ///
    legendfrom(lp_log) ///
    title("TFP densities by estimator and transformation") ///
    name(fig_problem4a, replace)

graph export "`figure_dir'/figure_problem4a.pdf", replace

*------------------------------------------------
* Figure 2: TFP in levels, separate by sector and estimator
*------------------------------------------------

twoway ///
    (kdensity TFP_WRDG if nace == 22, lcolor(sienna) lwidth(medthick)), ///
    title("Sector 22") ///
    legend(off) ///
    graphregion(color(white)) ///
    name(wrdg_lev_22, replace)

twoway ///
    (kdensity TFP_WRDG if nace == 36, lcolor(black) lwidth(medthick)), ///
    title("Sector 36") ///
    legend(off) ///
    graphregion(color(white)) ///
    name(wrdg_lev_36, replace)

graph combine wrdg_lev_22 wrdg_lev_36, cols(2) ///
    title("TFP distributions with WRDG") ///
    name(g_wrdg_lev, replace)

twoway ///
    (kdensity TFP_LP if nace == 22, lcolor(sienna) lwidth(medthick)), ///
    title("Sector 22") ///
    legend(off) ///
    graphregion(color(white)) ///
    name(lp_lev_22, replace)

twoway ///
    (kdensity TFP_LP if nace == 36, lcolor(black) lwidth(medthick)), ///
    title("Sector 36") ///
    legend(off) ///
    graphregion(color(white)) ///
    name(lp_lev_36, replace)

graph combine lp_lev_22 lp_lev_36, cols(2) ///
    title("TFP distributions with LP") ///
    name(g_lp_lev, replace)

graph combine g_wrdg_lev g_lp_lev, cols(1) imargin(tiny) ///
    title("TFP densities by estimator") ///
    name(fig_problem4a_levels, replace)

graph export "`figure_dir'/figure_problem4a_TFP_estim.pdf", replace

*------------------------------------------------
* Figure 3: log-TFP, separate by sector and estimator
*------------------------------------------------

twoway ///
    (kdensity ln_TFP_WRDG if nace == 22, lcolor(sienna) lwidth(medthick)), ///
    title("Sector 22") ///
    legend(off) ///
    graphregion(color(white)) ///
    name(wrdg_log_22, replace)

twoway ///
    (kdensity ln_TFP_WRDG if nace == 36, lcolor(black) lwidth(medthick)), ///
    title("Sector 36") ///
    legend(off) ///
    graphregion(color(white)) ///
    name(wrdg_log_36, replace)

graph combine wrdg_log_22 wrdg_log_36, cols(2) ///
    title("Log-TFP distributions with WRDG") ///
    name(g_wrdg_log, replace)

twoway ///
    (kdensity ln_TFP_LP if nace == 22, lcolor(sienna) lwidth(medthick)), ///
    title("Sector 22") ///
    legend(off) ///
    graphregion(color(white)) ///
    name(lp_log_22, replace)

twoway ///
    (kdensity ln_TFP_LP if nace == 36, lcolor(black) lwidth(medthick)), ///
    title("Sector 36") ///
    legend(off) ///
    graphregion(color(white)) ///
    name(lp_log_36, replace)

graph combine lp_log_22 lp_log_36, cols(2) ///
    title("Log-TFP distributions with LP") ///
    name(g_lp_log, replace)

graph combine g_wrdg_log g_lp_log, cols(1) imargin(tiny) ///
    title("Log-TFP densities by estimator") ///
    name(fig_problem4a_log, replace)

graph export "`figure_dir'/Q4a_log_TFP_estim.pdf", replace

*------------------------------------------------
* Figure 4: country-specific log-WRDG densities by sector
*------------------------------------------------

preserve

    keep if inlist(country, "FRA", "ITA") & inlist(nace, 22, 36)

    quietly count if country == "FRA" & nace == 22 & ln_TFP_WRDG < .
    local N_FRA22 = r(N)

    quietly count if country == "ITA" & nace == 22 & ln_TFP_WRDG < .
    local N_ITA22 = r(N)

    quietly count if country == "FRA" & nace == 36 & ln_TFP_WRDG < .
    local N_FRA36 = r(N)

    quietly count if country == "ITA" & nace == 36 & ln_TFP_WRDG < .
    local N_ITA36 = r(N)

    twoway ///
        (kdensity ln_TFP_WRDG if country == "FRA" & nace == 22, ///
            lcolor(navy) lwidth(medthick)) ///
        (kdensity ln_TFP_WRDG if country == "ITA" & nace == 22, ///
            lcolor(maroon) lwidth(medthick) lpattern(dash)), ///
        title("Sector 22: log-WRDG TFP by country") ///
        subtitle("France (N=`N_FRA22') vs Italy (N=`N_ITA22')") ///
        xtitle("log TFP (WRDG)") ///
        ytitle("Density") ///
        legend(order(1 "France" 2 "Italy")) ///
        graphregion(color(white)) ///
        name(g22_country, replace)

    twoway ///
        (kdensity ln_TFP_WRDG if country == "FRA" & nace == 36, ///
            lcolor(navy) lwidth(medthick)) ///
        (kdensity ln_TFP_WRDG if country == "ITA" & nace == 36, ///
            lcolor(maroon) lwidth(medthick) lpattern(dash)), ///
        title("Sector 36: log-WRDG TFP by country") ///
        subtitle("France (N=`N_FRA36') vs Italy (N=`N_ITA36')") ///
        xtitle("log TFP (WRDG)") ///
        ytitle("Density") ///
        legend(order(1 "France" 2 "Italy")) ///
        graphregion(color(white)) ///
        name(g36_country, replace)

    graph combine g22_country g36_country, cols(1) ///
        title("Country-specific log-WRDG TFP distributions by sector") ///
        graphregion(color(white)) ///
        name(g_country_wrdg, replace)

    graph export "`figure_dir'/Q4a_WRDG_country_split.pdf", replace

restore

*------------------------------------------------
* Figure 5: four country-sector WRDG panels
*------------------------------------------------

preserve

    keep if inlist(country, "FRA", "ITA") & inlist(nace, 22, 36)

    quietly count if country == "FRA" & nace == 22 & ln_TFP_WRDG < .
    local N_FRA22 = r(N)

    quietly count if country == "ITA" & nace == 22 & ln_TFP_WRDG < .
    local N_ITA22 = r(N)

    quietly count if country == "FRA" & nace == 36 & ln_TFP_WRDG < .
    local N_FRA36 = r(N)

    quietly count if country == "ITA" & nace == 36 & ln_TFP_WRDG < .
    local N_ITA36 = r(N)

    twoway ///
        (kdensity ln_TFP_WRDG if country == "FRA" & nace == 22, ///
            lcolor(navy) lwidth(medthick)), ///
        title("France, sector 22 (N=`N_FRA22')") ///
        xtitle("log TFP (WRDG)") ///
        ytitle("Density") ///
        legend(off) ///
        graphregion(color(white)) ///
        name(g_fra22, replace)

    twoway ///
        (kdensity ln_TFP_WRDG if country == "ITA" & nace == 22, ///
            lcolor(maroon) lwidth(medthick)), ///
        title("Italy, sector 22 (N=`N_ITA22')") ///
        xtitle("log TFP (WRDG)") ///
        ytitle("Density") ///
        legend(off) ///
        graphregion(color(white)) ///
        name(g_ita22, replace)

    twoway ///
        (kdensity ln_TFP_WRDG if country == "FRA" & nace == 36, ///
            lcolor(navy) lwidth(medthick)), ///
        title("France, sector 36 (N=`N_FRA36')") ///
        xtitle("log TFP (WRDG)") ///
        ytitle("Density") ///
        legend(off) ///
        graphregion(color(white)) ///
        name(g_fra36, replace)

    twoway ///
        (kdensity ln_TFP_WRDG if country == "ITA" & nace == 36, ///
            lcolor(maroon) lwidth(medthick)), ///
        title("Italy, sector 36 (N=`N_ITA36')") ///
        xtitle("log TFP (WRDG)") ///
        ytitle("Density") ///
        legend(off) ///
        graphregion(color(white)) ///
        name(g_ita36, replace)

    graph combine g_fra22 g_ita22 g_fra36 g_ita36, cols(2) ///
        title("Country- and sector-specific log-WRDG TFP densities") ///
        graphregion(color(white)) ///
        name(g_wrdg_4panels, replace)

    graph export "`figure_dir'/Q4a_WRDG_4panels.pdf", replace

restore

*************************************************
* Save cleaned sample
*************************************************
save `p1_clean', replace

************************************************************
* 4) Problem IV (b): Focus now on the (Wooldridge) TFP distributions of industry 22 in Italy and France. Do you find changes in these two TFP distributions in 2001 vs 2007? Look at changes in skewness in the same time window (again, focus on industry 22 only in these two countries). What happens?
************************************************************

use `p1_clean', clear


preserve
    keep if nace == 22 & inlist(country, "FRA", "ITA")

    * Density France: 2001 vs 2007
    tw (kdensity TFP_WRDG if country=="FRA" & year==2001, lcolor(navy) lwidth(medthick)) || (kdensity TFP_WRDG if country=="FRA" & year==2007, lcolor(orange) lwidth(medthick) lp(dash)), title("WRDG TFP - Sector 22, France") xtitle("TFP (WRDG)") ytitle("Density") legend(label(1 "2001") label(2 "2007"))
    graph save   "`figure_dir'/Q4b_WRDG_FRA.gph", replace
    graph export "`figure_dir'/Q4b_WRDG_FRA.png", replace

    * Density Italy: 2001 vs 2007
    tw (kdensity TFP_WRDG if country=="ITA" & year==2001, lcolor(navy) lwidth(medthick)) || (kdensity TFP_WRDG if country=="ITA" & year==2007, lcolor(orange) lwidth(medthick) lp(dash)), title("WRDG TFP - Sector 22, Italy") xtitle("TFP (WRDG)") ytitle("Density") legend(label(1 "2001") label(2 "2007"))
    graph save   "`figure_dir'/Q4b_WRDG_ITA.gph", replace
    graph export "`figure_dir'/Q4b_WRDG_ITA.png", replace

    * Both
    graph combine "`figure_dir'/Q4b_WRDG_FRA.gph" ///
        "`figure_dir'/Q4b_WRDG_ITA.gph", ///
        title("WRDG TFP Distributions - Sector 22 (2001 vs 2007)")
    graph export "`figure_dir'/Q4b_combined.png", replace

    *  Skewness statistics
    foreach ctry in FRA ITA {
        foreach yr in 2001 2007 {
            quietly sum TFP_WRDG if country=="`ctry'" & year==`yr', detail
            display "Country: `ctry'  Year: `yr'"
            display "  N        = " r(N)
            display "  Mean     = " r(mean)
            display "  Median   = " r(p50)
            display "  Std dev  = " r(sd)
            display "  Skewness = " r(skewness)
            display "  Kurtosis = " r(kurtosis)
        }
    }

restore

********************************************************************************
* Problem IV (c) Do you find the shifts to be homogenous throughout the distribution? Once you have defined a specific parametrical distribution for the TFP, is there a way through which you can statistically measure the changes in the TFP distribution in the industry over time (2001 vs 2007)?
********************************************************************************

preserve

    * Focus on sector 22 and the two countries of interest
    keep if nace == 22 & inlist(country, "FRA", "ITA")

    *------------------------------------------------------------
    * Build empirical CDF within country x year cells
    *------------------------------------------------------------
    sort country year TFP_WRDG
    by country year: cumul TFP_WRDG, generate(cum_TFP_WRDG)

    * Log survival function
    * Exclude the top observation in each cell to avoid log(0)
    gen rhs_WRDG = log(1 - cum_TFP_WRDG) if cum_TFP_WRDG < 1

    *------------------------------------------------------------
    * France
    *------------------------------------------------------------
    qui reg rhs_WRDG ln_TFP_WRDG if country=="FRA"
    outreg2 using "`table_dir'/Pareto_FRA_22.tex", replace tex ///
        title("Pareto Distribution - France, Sector 22") ///
        ctitle("All years")

    qui reg rhs_WRDG ln_TFP_WRDG if country=="FRA" & year==2001
    outreg2 using "`table_dir'/Pareto_FRA_22.tex", append tex ///
        ctitle("2001")

    qui reg rhs_WRDG ln_TFP_WRDG if country=="FRA" & year==2007
    outreg2 using "`table_dir'/Pareto_FRA_22.tex", append tex ///
        ctitle("2007")

    *------------------------------------------------------------
    * Italy
    *------------------------------------------------------------
    qui reg rhs_WRDG ln_TFP_WRDG if country=="ITA"
    outreg2 using "`table_dir'/Pareto_ITA_22.tex", replace tex ///
        title("Pareto Distribution - Italy, Sector 22") ///
        ctitle("All years")

    qui reg rhs_WRDG ln_TFP_WRDG if country=="ITA" & year==2001
    outreg2 using "`table_dir'/Pareto_ITA_22.tex", append tex ///
        ctitle("2001")

    qui reg rhs_WRDG ln_TFP_WRDG if country=="ITA" & year==2007
    outreg2 using "`table_dir'/Pareto_ITA_22.tex", append tex ///
        ctitle("2007")

    *------------------------------------------------------------
    * Display Pareto slope coefficients in Stata output
    *------------------------------------------------------------
    foreach ctry in FRA ITA {
        foreach yr in 2001 2007 {
            qui reg rhs_WRDG ln_TFP_WRDG if country=="`ctry'" & year==`yr'
            di "Pareto slope | Country: `ctry'  Year: `yr'  -> beta = " ///
               _b[ln_TFP_WRDG] "  (se = " _se[ln_TFP_WRDG] ")"
        }
    }

restore

************************************************************
* Problem IV (d): Combine LP TFP for sectors 22 and 36 and
* estimate export, pure-exporter, and FDI/multinational premia
************************************************************

* Note: TFP_LP and ln_TFP_LP were already created in Problem IV(a).
* Outliers were set to missing, not physically dropped.
* We therefore do not create an additional tfp_sample variable here:
* Stata automatically excludes observations with missing ln_TFP_LP in
* regressions and density plots. For composition tables, we use
* !missing(ln_TFP_LP) directly so that the reported groups refer to the
* same cleaned LP-TFP observations used in the analysis.

*---------------------------------------------------------*
* Step 1: Define export status
* 0 = domestic only
* 1 = pure exporter
* 2 = exporter + FDI
*---------------------------------------------------------*

capture drop export_status
gen export_status = .

replace export_status = 0 if exporter == 0 & FDI == 0
replace export_status = 1 if exporter == 1 & FDI == 0
replace export_status = 2 if exporter == 1 & FDI == 1

tab export_status, missing

* Some firms have FDI == 1 but exporter == 0.
* These are anomalous relative to the standard export/FDI hierarchy and
* are left outside the three-way classification used below.

* Check export-status composition after LP-TFP cleaning
tab export_status if !missing(ln_TFP_LP), missing

*---------------------------------------------------------*
* Step 2: Composition tables on the cleaned LP-TFP sample
*---------------------------------------------------------*

* Domestic firms: country x sector composition
tab country nace if !missing(ln_TFP_LP) & export_status == 0, missing

* Pure exporters: country x sector composition
tab country nace if !missing(ln_TFP_LP) & export_status == 1, missing

* Multinationals: country x sector composition
tab country nace if !missing(ln_TFP_LP) & export_status == 2, missing

* Sector shares for text: domestic firms
count if !missing(ln_TFP_LP) & export_status == 0
local N_dom = r(N)

count if !missing(ln_TFP_LP) & export_status == 0 & nace == 22
local N_dom_22 = r(N)

count if !missing(ln_TFP_LP) & export_status == 0 & nace == 36
local N_dom_36 = r(N)

display "Domestic total in cleaned LP-TFP sample = `N_dom'"
display "Domestic sector 22 = `N_dom_22'"
display "Domestic sector 36 = `N_dom_36'"
display "Share of domestic firms in sector 22 = " 100 * `N_dom_22' / `N_dom'

* Sector shares for text: pure exporters
count if export_status == 1
local N_exp = r(N)

count if export_status == 1 & nace == 22
local N_exp_22 = r(N)

count if export_status == 1 & nace == 36
local N_exp_36 = r(N)

display "Pure exporter total in cleaned LP-TFP sample = `N_exp'"
display "Pure exporter sector 22 = `N_exp_22'"
display "Pure exporter sector 36 = `N_exp_36'"
display "Share of pure exporters in sector 36 = " 100 * `N_exp_36' / `N_exp'

* Sector-level LP-TFP summary
tabstat ln_TFP_LP if inlist(export_status, 0, 1, 2), ///
    by(nace) stat(mean median sd n)

*---------------------------------------------------------*
* Step 3: Visualise productivity distributions by status
*---------------------------------------------------------*

twoway ///
    (kdensity ln_TFP_LP if export_status == 2, lw(medthick) lcolor(green)) ///
    (kdensity ln_TFP_LP if export_status == 1, lw(medthin)  lcolor(sienna)) ///
    (kdensity ln_TFP_LP if export_status == 0, lw(medthin)  lcolor(blue) lp(dash)), ///
    title("LP TFP distributions by export status") ///
    xtitle("log TFP (LP)") ytitle("Density") ///
    legend(label(1 "Multinationals (Exporters + FDI)") ///
           label(2 "Pure exporters") ///
           label(3 "Domestic only"))

graph export "`figure_dir'/Q4d_TFP_by_status.png", replace

*---------------------------------------------------------*
* Step 4: All exporters vs non-exporters
* This compares all exporting firms, including exporters with FDI,
* against non-exporters.
*---------------------------------------------------------*

xi: reg ln_TFP_LP exporter i.year i.nace i.country ///
    if inlist(export_status, 0, 1, 2), robust

estimates store all_export_premium

outreg2 using "`table_dir'/table_Q4d_premium.tex", replace ///
    title("Export and FDI Premium") ctitle("All exporters") ///
    addtext(Year FE, YES, Sector FE, YES, Country FE, YES) ///
    drop(_Iyear* _Inace* _Icountry*)

*---------------------------------------------------------*
* Step 5: Pure exporter premium
* Compare pure exporters (status 1) vs domestic firms (status 0).
* Multinationals are excluded.
*---------------------------------------------------------*

xi: reg ln_TFP_LP exporter i.year i.nace i.country ///
    if export_status == 0 | export_status == 1, robust

estimates store pure_export_premium

outreg2 using "`table_dir'/table_Q4d_premium.tex", append ///
    ctitle("Pure exporters") ///
    addtext(Year FE, YES, Sector FE, YES, Country FE, YES) ///
    drop(_Iyear* _Inace* _Icountry*)

*---------------------------------------------------------*
* Step 6: FDI / multinational premium
* Compare exporters with FDI (status 2) vs domestic firms (status 0).
* Pure exporters are excluded.
*
* In this restricted sample, exporter and FDI are identical:
* domestic firms have exporter == 0 and FDI == 0, while status-2 firms
* have exporter == 1 and FDI == 1. Therefore, using exporter or FDI
* would give the same coefficient.
*
* We use FDI as the regressor because the coefficient is interpreted as
* the FDI / multinational premium. Firms with FDI == 1 and exporter == 0
* have export_status missing and are not included in this comparison.
*---------------------------------------------------------*

xi: reg ln_TFP_LP FDI i.year i.nace i.country ///
    if export_status == 0 | export_status == 2, robust

estimates store fdi_premium

outreg2 using "`table_dir'/table_Q4d_premium.tex", append ///
    ctitle("FDI premium") ///
    addtext(Year FE, YES, Sector FE, YES, Country FE, YES) ///
    drop(_Iyear* _Inace* _Icountry*)

xi: reg ln_TFP_LP exporter i.year i.nace i.country ///
    if export_status == 0 | export_status == 2, robust
xi: reg ln_TFP_LP FDI i.year i.nace i.country ///
    if export_status == 0 | export_status == 2, robust
estimates store fdi_premium

outreg2 using "`table_dir'/table_Q4d_premium.tex", append ///
    ctitle("FDI premium") ///
    addtext(Year FE, YES, Sector FE, YES, Country FE, YES) ///
    drop(_Iyear* _Inace* _Icountry*)
*---------------------------------------------------------*
* Step 7: Exporters with FDI vs pure exporters
* Compare multinationals/exporters with FDI (status 2)
* to pure exporters (status 1).
* Domestic firms are excluded.
*
* Here FDI is the correct regressor:
* - export_status == 1: exporter == 1, FDI == 0
* - export_status == 2: exporter == 1, FDI == 1
* Therefore, the coefficient on FDI measures the additional
* productivity premium of exporters with FDI relative to pure exporters.
*---------------------------------------------------------*

xi: reg ln_TFP_LP FDI i.year i.nace i.country ///
    if export_status == 1 | export_status == 2, robust

estimates store fdi_vs_exporter_premium

outreg2 using "`table_dir'/table_Q4d_premium.tex", append ///
    ctitle("FDI vs exporters") ///
    addtext(Year FE, YES, Sector FE, YES, Country FE, YES) ///
    drop(_Iyear* _Inace* _Icountry*)

*---------------------------------------------------------*
* FDI premium:
* Multinationals vs domestic + pure exporters
* Compare status 2 to status 0 and 1 together.
*---------------------------------------------------------*

xi: reg ln_TFP_LP FDI i.year i.nace i.country ///
    if inlist(export_status, 0, 1, 2), robust

estimates store fdi_vs_all_nonfdi

outreg2 using "`table_dir'/table_Q4d_premium.tex", append ///
    ctitle("FDI vs non-FDI") ///
    addtext(Year FE, YES, Sector FE, YES, Country FE, YES) ///
    drop(_Iyear* _Inace* _Icountry*)


************************************************************
**# Problem V
* Problem V (a): PCM and DLW markup estimation
************************************************************
use `p1_clean', clear
*---------------------------------------------------------
* Step 1: Recover beta_L from LP estimation for each sector
*---------------------------------------------------------

* Sector 22
xi: levpet ln_real_VA if nace == 22, ///
    free(ln_L i.country i.year) ///
    proxy(ln_real_M) ///
    capital(ln_real_K) ///
    reps(50) level(99) va

scalar beta_L_22 = _b[ln_L]
display "beta_L sector 22 (LP) = " beta_L_22

* Sector 36
xi: levpet ln_real_VA if nace == 36, ///
    free(ln_L i.country i.year) ///
    proxy(ln_real_M) ///
    capital(ln_real_K) ///
    reps(50) level(99) va

scalar beta_L_36 = _b[ln_L]
display "beta_L sector 36 (LP) = " beta_L_36
* In the constant-markup Melitz world, markups should be roughly constant.
* In real data, they are not. A simple accounting proxy is:
* PCM = (sales - wages - materials) / sales
*
* This is not a full structural markup estimate, but it is informative.
*---------------------------------------------------------
* Step 2: PCM markup
* variable_costs = M + W
* In the constant-markup Melitz world, markups should be roughly constant.
* In real data, they are not. A simple accounting proxy is:
* PCM = (sales - wages - materials) / sales
*
* This is not a full structural markup estimate, but it is informative.
*---------------------------------------------------------
capture drop PCM markup_PCM alpha_L markup_DLW

gen PCM = (sales - M - W) / sales if sales > 0
sum PCM, detail
replace PCM = . if !inrange(PCM, r(p1), r(p99))

gen markup_PCM = 1 / (1 - PCM) if PCM < 1

*---------------------------------------------------------
* Step 3: DLW markup
* alpha_L = labour share in nominal revenue
*---------------------------------------------------------
gen alpha_L = W / sales if sales > 0 & W >= 0

gen markup_DLW = .
replace markup_DLW = beta_L_22 / alpha_L if nace == 22 & alpha_L > 0
replace markup_DLW = beta_L_36 / alpha_L if nace == 36 & alpha_L > 0

foreach s in 22 36 {
    sum markup_DLW if nace == `s', detail
    replace markup_DLW = . if !inrange(markup_DLW, r(p1), r(p99)) & nace == `s'
}

*---------------------------------------------------------
* Step 4: Plot both distributions
*---------------------------------------------------------

* Plot PCM (Lerner index)
kdensity PCM

* Then plot both markups together
twoway ///
    (kdensity markup_DLW, lcolor(green) lwidth(medthick)) ///
    (kdensity markup_PCM, lcolor(sienna) lwidth(medthick)), ///
    title("DLW markup vs PCM") ///
    xtitle("Markup") ytitle("Density") ///
    legend(label(1 "DLW markup") label(2 "PCM markup"))

graph export "`figure_dir'/Q5a_markup_DLW_vs_PCM.png", replace
* Markups differ across firms, so firms do not all have the same degree
* of market power. Differences across firms therefore reflect not only
* productivity differences, but also differences in the ability to charge
* prices above marginal cost.
*
* If the most productive firms also set higher markups, then the cost
* savings generated by higher productivity are not fully passed on to
* consumers through lower prices. Instead, part of these gains is kept
* by firms as higher profits. This means that the standard trade-model
* prediction of full pass-through from productivity gains to lower prices
* may not hold.
tabstat markup_PCM markup_DLW, stat(mean median p25 p75 sd) columns(statistics)
* Gap between the two markups by sector
gen markup_gap = markup_PCM - markup_DLW

tabstat markup_gap, by(nace) stat(mean median sd n)

* Also check capital intensity by sector as background
tabstat real_K, by(nace) stat(mean median)
tabstat alpha_L, by(nace) stat(mean median)
tabstat alpha_L W real_M, by(nace) stat(mean)
gen K_intensity = real_K / L

tabstat K_intensity, by(nace) stat(mean median)
gen total_costs = W + real_M + real_K
gen alpha_K_share = real_K / total_costs
gen alpha_M_share = real_M / total_costs
gen alpha_W_share = W / total_costs

tabstat alpha_K_share alpha_M_share alpha_W_share, by(nace) stat(mean)

* Is the bimodality in DLW driven by sectors?
twoway ///
    (kdensity markup_DLW if nace == 22, lcolor(sienna)) ///
    (kdensity markup_DLW if nace == 36, lcolor(black)), ///
    title("DLW markup by sector") ///
    legend(label(1 "Sector 22") label(2 "Sector 36"))

* Same for PCM
twoway ///
    (kdensity markup_PCM if nace == 22, lcolor(sienna)) ///
    (kdensity markup_PCM if nace == 36, lcolor(black)), ///
    title("PCM markup by sector") ///
    legend(label(1 "Sector 22") label(2 "Sector 36"))

* Gap by sector — already done, confirms sector 22 drives the bias
tabstat markup_gap, by(nace) stat(mean median)

* Gap by country
tabstat markup_gap, by(country) stat(mean median)

* Gap by year — is the bias growing over time?
egen country_nace = group(country nace), label
tabstat markup_gap, by(year) stat(mean median)
tabstat markup_gap, by(country_nace) stat(mean median)
tabstat markup_DLW markup_PCM alpha_L, by(country_nace) stat(mean)

************************************************************
* Problem V (b): Exporters, DLW markup, and productivity
************************************************************

*---------------------------------------------------------
* 1) DLW markup on exporter dummy
*---------------------------------------------------------
reg markup_DLW exporter i.year i.nace, robust
estimates store q5b_1

reg markup_DLW exporter ln_L i.year i.nace, robust
estimates store q5b_2

*---------------------------------------------------------
* 2) Wooldridge productivity on DLW markup
*---------------------------------------------------------
reg ln_TFP_WRDG markup_DLW i.year i.nace, robust
estimates store q5b_3

*---------------------------------------------------------
* 3) Export regression table
*---------------------------------------------------------
reg markup_DLW exporter i.year i.nace, robust
outreg2 using "`table_dir'/table_problem5b.tex", replace tex ///
    ctitle("Markup: no size") ///
    addtext(Year FE, YES, Sector FE, YES)

reg markup_DLW exporter ln_L i.year i.nace, robust
outreg2 using "`table_dir'/table_problem5b.tex", append tex ///
    ctitle("Markup: + size") ///
    addtext(Year FE, YES, Sector FE, YES)

reg ln_TFP_WRDG markup_DLW i.year i.nace, robust
outreg2 using "`table_dir'/table_problem5b.tex", append tex ///
    ctitle("TFP on markup") ///
    addtext(Year FE, YES, Sector FE, YES)


*APPENDIX CHECK
* Check that ln_TFP_LP exists
describe ln_TFP_LP country nace

* Main table: mean, median, sd, N by country x sector
tabstat ln_TFP_LP if inlist(country,"FRA","ITA") & inlist(nace,22,36), ///
    by(country_nace) ///
    stat(mean median sd n)

* If country_nace does not exist, create it
capture confirm variable country_nace
if _rc {
    egen country_nace = group(country nace), label
}

tabstat ln_TFP_LP if inlist(country,"FRA","ITA") & inlist(nace,22,36), ///
    by(country_nace) ///
    stat(mean median sd n)

* Also check sector totals
tabstat ln_TFP_LP if inlist(nace,22,36), ///
    by(nace) ///
    stat(mean median sd n)

* Optional: exact country x sector counts
table country nace, statistic(count ln_TFP_LP) ///
                   statistic(mean ln_TFP_LP) ///
                   statistic(median ln_TFP_LP) ///
                   statistic(sd ln_TFP_LP)

log close

*=============================================================================*
* PART II - PROBLEM VI (a-c)
* Final version:
* - dataset C not used
* - US-IV corrected to recover 2007
* - final regional-average shock built over 1995-2007
*=============================================================================*

clear
capture log close
log using "`log_dir'/take_home_2026_part2.log", text replace

foreach required_file in ///
    "`employment_data'" ///
    "`china_imports'" ///
    "`us_imports'" {
    capture confirm file "`required_file'"
    if _rc {
        display as error "Required Problem VI input not found: `required_file'"
        display as error "See data/README.md."
        exit 601
    }
}

foreach extension in shp shx dbf prj cpg {
    capture confirm file "`data_dir'/NUTS_RG_20M_2013_3035.`extension'"
    if _rc {
        display as error "Required geographic input not found: NUTS_RG_20M_2013_3035.`extension'"
        display as error "Place the complete shapefile bundle in data/."
        exit 601
    }
}
*----------------------------------------------*
**# Problem VI(a)
*Build China shock and US-IV shock
* without using dataset C
*----------------------------------------------*

*----------------------------------------------*
* 1. Build pre-sample employment weights
*----------------------------------------------*
use "`employment_data'", clear

gen ratio_left = empl / tot_empl_nuts2
keep country nuts2 nuts2_name nace year ratio_left tot_empl_country_nace
sort country nuts2 nace year
save `weights_pre', replace


*----------------------------------------------*
* 2. China shock by region-year (EU shock)
*    Delta imports = imports(t-1) - imports(t-6)
*    Valid years start in 1994
*----------------------------------------------*
use "`china_imports'", clear
sort country nace year
merge 1:m country year nace using `weights_pre', nogen keep(match)

egen panel_id = group(country nace nuts2)
xtset panel_id year

gen imp_t1 = L.real_imports_china
gen imp_t6 = L6.real_imports_china
gen delta_imp_china = imp_t1 - imp_t6

* keep only years for which the 5-year delta is actually computable
* (first: check whether year >= 1994 is enough, or whether some deltas are still missing)
*count if year >= 1994
*count if year >= 1994 & missing(delta_imp_china)

* Disabled diagnostic retained from the definitive source:
* list country nace nuts2 nuts2_name year real_imports_china imp_t1 imp_t6 delta_imp_china ///
*     if year >= 1994 & missing(delta_imp_china), sepby(country nace) abbreviate(20)

*tab year if year >= 1994 & missing(delta_imp_china)
*tab country if year >= 1994 & missing(delta_imp_china)
*tab nace if year >= 1994 & missing(delta_imp_china)
* Keep only observations with a valid import delta.
* Some country-industry series, e.g. Spain-NACE DF in 1994-1995,
* still have missing L6 imports even after 1994. Dropping missing
* deltas avoids treating unavailable shock components as zero.
keep if year >= 1994 & !missing(delta_imp_china)

gen china_component = ratio_left * (delta_imp_china / tot_empl_country_nace)
bys country nuts2 nuts2_name year: egen china_shock = total(china_component)

keep country nuts2 nuts2_name year china_shock
duplicates drop
save `china_region_year', replace


*----------------------------------------------*
* 3. IV shock based on US imports
*    Corrected to recover 2007
*    Valid years become 1995-2007
*----------------------------------------------*
use "`us_imports'", clear

* create one extra row per industry for year 2007,
* so that L.real_USimports_china and L6.real_USimports_china
* can be computed on the 2007 observation
preserve
    keep if year == 2006
    replace year = 2007
    replace real_USimports_china = .
    save `us2007'
restore

append using `us2007'
* The US import file ends in 2006. To compute the 2007 IV shock
* according to IMP(t-1)-IMP(t-6), we need an empty 2007 row:
* L.real_USimports_china will use 2006, and L6 will use 2001.
* We are NOT imputing 2007 imports.
sort nace year
merge 1:m year nace using `weights_pre', nogen keep(match)

egen panel_id_us = group(country nuts2 nace)
xtset panel_id_us year

gen imp_t1_us = L.real_USimports_china
gen imp_t6_us = L6.real_USimports_china
gen delta_imp_us = imp_t1_us - imp_t6_us

* keep only years for which the 5-year delta is actually computable
* (first: like before, check whether the chosen year window still contains missing IV deltas)
*count if inrange(year, 1995, 2007)
*count if inrange(year, 1995, 2007) & missing(delta_imp_us)

* Disabled diagnostic retained from the definitive source:
* list country nace nuts2 nuts2_name year real_USimports_china imp_t1_us imp_t6_us delta_imp_us ///
*     if inrange(year, 1995, 2007) & missing(delta_imp_us), sepby(country nace) abbreviate(20)

*tab year if inrange(year, 1995, 2007) & missing(delta_imp_us)
*tab country if inrange(year, 1995, 2007) & missing(delta_imp_us)
*tab nace if inrange(year, 1995, 2007) & missing(delta_imp_us)
** For the US-IV shock, the 1995-2007 window contains no missing
* import deltas after adding the empty 2007 row, so this restriction
* keeps only computable IMP(t-1)-IMP(t-6) changes.
keep if inrange(year, 1995, 2007)

gen us_component = ratio_left * (delta_imp_us / tot_empl_country_nace)
bys country nuts2 nuts2_name year: egen china_shock_us = total(us_component)

keep country nuts2 nuts2_name year china_shock_us
duplicates drop
save `us_region_year', replace


*----------------------------------------------*
**# Problem VI(b)
* Collapse by region to obtain
* the average China shock over 1995-2007
*----------------------------------------------*

* EU shock regional average, 1995-2007
use `china_region_year', clear
keep if inrange(year, 1995, 2007)

collapse (mean) china_shock, by(country nuts2 nuts2_name)
save `avg_china', replace

* US-IV regional average, 1995-2007
use `us_region_year', clear
keep if inrange(year, 1995, 2007)

collapse (mean) china_shock_us, by(country nuts2 nuts2_name)
save `avg_us', replace

* Final regional-average dataset for later use
use `avg_china', clear
merge 1:1 country nuts2 using `avg_us'

tab _merge
keep if _merge == 3
drop _merge

save `regional_shocks', replace


*----------------------------------------------*
* Optional summaries
*----------------------------------------------*
summarize china_shock china_shock_us
sort china_shock
list country nuts2 china_shock china_shock_us in 1/10, noobs
list country nuts2 china_shock china_shock_us in -9/l, noobs


*----------------------------------------------*
**#Problem VI(c)
* Maps:
* China shock map: regional average over 1995-2007
* Manufacturing share map: pre-sample year 1988
*----------------------------------------------*

* Package availability and portable directories were checked during setup.
*-----------------------------------------------------*
* 3. Convert shapefile into Stata files
*-----------------------------------------------------*
shp2dta using "`nuts_shp'", ///
    database("`intermediate_dir'/nuts2_db.dta") ///
    coordinates("`intermediate_dir'/nuts2_coord.dta") ///
    genid(id) replace

*=====================================================*
* PART A. MAP OF AVERAGE CHINA SHOCK
*=====================================================*

*-----------------------------------------------------*
* 4. Prepare China shock cross-section for mapping
*-----------------------------------------------------*
use `regional_shocks', clear

rename nuts2 NUTS_ID
sort NUTS_ID
save `shock_mapdata', replace

*-----------------------------------------------------*
* 5. Prepare map database and merge with China shock
*-----------------------------------------------------*
use "`intermediate_dir'/nuts2_db.dta", clear

* Keep only Spain, France, Italy
capture confirm variable CNTR_CODE
if !_rc keep if inlist(CNTR_CODE,"ES","FR","IT")

* Keep only NUTS-2 regions
capture confirm variable STAT_LEVL_
if !_rc keep if STAT_LEVL_==2

capture confirm variable LEVL_CODE
if !_rc keep if LEVL_CODE==2

sort NUTS_ID
merge 1:1 NUTS_ID using `shock_mapdata'

tab _merge
keep if _merge == 3
drop _merge

save "`intermediate_dir'/nuts2_china_shock_db.dta", replace

*-----------------------------------------------------*
* 6. Plot map of China shock
*-----------------------------------------------------*
spmap china_shock using "`intermediate_dir'/nuts2_coord.dta", id(id) ///
    fcolor(Purples) ///
    clmethod(kmeans) clnumber(8) ///
    ocolor(black ..) osize(thin ..) ///
    title("Average China Shock by NUTS-2 Region") ///
    subtitle("Regional average over 1995-2007; no dataset C used") ///
    note("Regional China shock averaged directly from region-year data") ///
    legend(pos(7) ring(0) size(vsmall) region(fcolor(white) lcolor(white) margin(small))) ///
    saving("`map_dir'/map_china_shock.gph", replace)

graph export "`map_dir'/map_china_shock.pdf", as(pdf) replace
graph export "`map_dir'/map_china_shock.png", as(png) replace


*=====================================================*
* PART B. MAP OF PRE-SAMPLE MANUFACTURING SHARE
*=====================================================*

*-----------------------------------------------------*
* 7. Compute pre-sample manufacturing share
*-----------------------------------------------------*
use "`employment_data'", clear

keep if year == 1988

collapse (sum) empl (first) tot_empl_nuts2, by(country nuts2 nuts2_name)

gen manuf_share = empl / tot_empl_nuts2

rename nuts2 NUTS_ID
sort NUTS_ID
save `manuf_mapdata', replace

*-----------------------------------------------------*
* 8. Prepare map database and merge with manuf share
*-----------------------------------------------------*
use "`intermediate_dir'/nuts2_db.dta", clear

* Keep only Spain, France, Italy
capture confirm variable CNTR_CODE
if !_rc keep if inlist(CNTR_CODE,"ES","FR","IT")

* Keep only NUTS-2 regions
capture confirm variable STAT_LEVL_
if !_rc keep if STAT_LEVL_==2

capture confirm variable LEVL_CODE
if !_rc keep if LEVL_CODE==2

sort NUTS_ID
merge 1:1 NUTS_ID using `manuf_mapdata'

tab _merge
keep if _merge == 3
drop _merge

save "`intermediate_dir'/nuts2_manuf_share_db.dta", replace

*-----------------------------------------------------*
* 9. Plot map of manufacturing share
*-----------------------------------------------------*
spmap manuf_share using "`intermediate_dir'/nuts2_coord.dta", id(id) ///
    fcolor(Reds) ///
    clmethod(kmeans) clnumber(8) ///
    ocolor(black ..) osize(thin ..) ///
    title("Pre-sample Manufacturing Employment Share by NUTS-2 Region") ///
    subtitle("1988 baseline") ///
    note("Manufacturing share = manufacturing employment / total regional employment") ///
    legend(pos(7) ring(0) size(vsmall) region(fcolor(white) lcolor(white) margin(small))) ///
    saving("`map_dir'/map_manuf_share.gph", replace)

graph export "`map_dir'/map_manuf_share.pdf", as(pdf) replace
graph export "`map_dir'/map_manuf_share.png", as(png) replace


*----------------------------------------------*
**#Problem VII(a)
*Merge the ESS dataset with data on the China shock (region-specific average), based on the region of residence of each respondent.
*----------------------------------------------*

foreach required_file in "`ess_data'" "`cmp_data'" {
    capture confirm file "`required_file'"
    if _rc {
        display as error "Required Problem VII input not found: `required_file'"
        display as error "See data/README.md."
        exit 601
    }
}

use `regional_shocks', clear

* Recode old French NUTS2 codes into the ESS Round 8 NUTS2 codes.
replace nuts2 = "FRB0" if nuts2 == "FR24"
replace nuts2 = "FRC1" if nuts2 == "FR26"
replace nuts2 = "FRC2" if nuts2 == "FR43"
replace nuts2 = "FRD1" if nuts2 == "FR25"
replace nuts2 = "FRD2" if nuts2 == "FR23"
replace nuts2 = "FRE1" if nuts2 == "FR30"
replace nuts2 = "FRE2" if nuts2 == "FR22"
replace nuts2 = "FRF1" if nuts2 == "FR42"
replace nuts2 = "FRF2" if nuts2 == "FR21"
replace nuts2 = "FRF3" if nuts2 == "FR41"
replace nuts2 = "FRG0" if nuts2 == "FR51"
replace nuts2 = "FRH0" if nuts2 == "FR52"
replace nuts2 = "FRI1" if nuts2 == "FR61"
replace nuts2 = "FRI2" if nuts2 == "FR63"
replace nuts2 = "FRI3" if nuts2 == "FR53"
replace nuts2 = "FRJ1" if nuts2 == "FR81"
replace nuts2 = "FRJ2" if nuts2 == "FR62"
replace nuts2 = "FRK1" if nuts2 == "FR72"
replace nuts2 = "FRK2" if nuts2 == "FR71"
replace nuts2 = "FRL0" if nuts2 == "FR82"

* FR10 already has the same code in the old and new NUTS classification.
replace nuts2 = "FR10" if nuts2 == "FR10"

* Keep only the 21 metropolitan French NUTS2 regions required by the assignment.
drop if inlist(nuts2, "FR83", "FRM0")

* Check that the recoded regional shock file is clean.
duplicates report nuts2
tab nuts2

save `prob7_shocks', replace


use "`ess_data'", clear

	keep if cntry == "FR"

	keep pspwght gndr agea edlvdfr region prtvtcfr sbeqsoc

	rename region nuts2
	gen female = .
	replace female = 0 if gndr == 1
	replace female = 1 if gndr == 2

	save `ess_france', replace



merge m:1 nuts2 using `prob7_shocks', keep(match)

	drop _merge

save `problem7_ab', replace

*---------------------------------------------------*
* Prepare NUTS identifiers for fixed effects/clustering
*---------------------------------------------------*

* NUTS1 = first three characters of the NUTS2 code
capture drop nuts1
gen nuts1 = substr(nuts2, 1, 3)

* Encode string region identifiers into numeric variables.
* This is safer for fixed effects and clustering.
capture drop nuts1_id nuts2_id
encode nuts1, gen(nuts1_id)
encode nuts2, gen(nuts2_id)

label variable nuts1_id "NUTS1 fixed effects"
label variable nuts2_id "NUTS2 cluster"

*----------------------------------------------*
**# Problem VII(b)
* Regress (simple OLS) the perception score about whether social benefits and services lead to a more equal society on the region-level China shock previously constructed, controlling for gender, age, dummies for levels of education, and dummies for NUTS regions at the 1-digit level. Cluster the standard errors by NUTS regions at the 2-digit level. Be sure to use survey weights in the regression. Comment and discuss possible endogeneity issues. */
*----------------------------------------------*
xi: reg sbeqsoc china_shock female agea i.edlvdfr i.nuts1_id [pweight=pspwght], vce(cluster nuts2_id)
eststo OLS_perception
scalar R2 = e(r2)
scalar R2_a = e(r2_a)
scalar F_ols = e(F)
estadd scalar R2
estadd scalar R2_a
estadd scalar F_ols

*---------------------------------------------------*


*---------------------------------------------------*
**# Problem VII(c)
* To correct for endogeneity issues, use the instrumental variable you have built before, based on changes in Chinese imports to the USA. Discuss the rationale for using this instrumental variable. What happens when you instrument the China shock in the previous regression? */
*---------------------------------------------------*

* Package availability was checked in the repository setup block.

* Reduced-form / first stage explicitly
xi: reg china_shock china_shock_us female agea i.edlvdfr i.nuts1_id ///
    [pweight=pspwght], vce(cluster nuts2_id)
eststo First_Stage_VIIc
scalar F_1st_red = e(F)

* 2SLS with ivreg2
xi: ivreg2 sbeqsoc (china_shock = china_shock_us) ///
    female agea i.edlvdfr i.nuts1_id ///
    [pweight=pspwght], cluster(nuts2_id) first
scalar F_KP = e(widstat)

* 2SLS with ivregress
xi: ivregress 2sls sbeqsoc (china_shock = china_shock_us) ///
    female agea i.edlvdfr i.nuts1_id ///
    [pweight=pspwght], vce(cluster nuts2_id)
eststo IV_perception
estadd scalar F_KP

* Effect size in standard-deviation units
scalar beta_IV = e(b)[1,1]
quietly sum china_shock
scalar shock_sd = r(sd)
scalar effect_IV_sd = beta_IV * shock_sd
display "1-SD IV effect on sbeqsoc: " effect_IV_sd

quietly sum sbeqsoc
scalar mean_dv = r(mean)
scalar std_IV_effect = abs(effect_IV_sd / mean_dv)
display "Standardised IV effect (relative to mean of sbeqsoc): " std_IV_effect

* Side-by-side OLS vs 2SLS table
label var china_shock    "China shock"
label var china_shock_us "China shock instrument (US-from-China)"

esttab OLS_perception IV_perception First_Stage_VIIc ///
    using "`table_dir'/table_problem7c.tex", replace ///
    keep(china_shock china_shock_us) ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2 F_KP, fmt(%9.0fc 3 3) ///
          labels("Observations" "R^2" "Kleibergen-Paap F")) ///
    mtitles("OLS" "2SLS" "First stage") ///
    title("VII(c): OLS vs IV - effect of China shock on sbeqsoc")

save `problem7_c', replace

*---------------------------------------------------*
**# Problem VII(d)
* Comment on the sign of the coeﬃcient on the China shock obtained at point c. Provide intuitive theoretical arguments to rationalize this finding. */
*---------------------------------------------------*

* Find answer on the report

*---------------------------------------------------*
**# Problem VII(e)
* Starting from the augmented ESS dataset used in the previous regressions, atach to the variable "party voted in last national election" the score for corporatism and mixed economy (i.e., "Favourable mentions of cooperation of government, employers, and trade unions simultaneously") available in the Manifesto Project for the election of 2012. You can search in the codebook the code for this score in the dataset. Please note that party names do not necessarily match exactly, and that ESS may have more parties than coded by the Manifesto Project. In the end, you should be able to match 9 parties. */
*---------------------------------------------------*

preserve
    use "`cmp_data'", clear
    keep if countryname == "France" & date == 201206
    keep party partyname partyabbrev per405
    rename party        party_cmp
    rename partyname    partyname_cmp
    rename partyabbrev  partyabbrev_cmp
    list party_cmp partyname_cmp partyabbrev_cmp per405, noobs sep(0)
    save `mp_france', replace
restore

* Start from ESS augmented dataset from previous points:
use `problem7_c', clear

* Map ESS prtvtcfr to Manifesto Project party IDs for France 2012:
*(First: check all 9 parties are present in the 2012 Manifesto file)
*list party_cmp partyname_cmp partyabbrev_cmp per405, noobs sep(0)

gen long party_cmp = .
replace party_cmp = 31630 if prtvtcfr == 1   // Nouveau Centre  (NC)
replace party_cmp = 31720 if prtvtcfr == 2   // Front National  (FN)
replace party_cmp = 31421 if prtvtcfr == 3   // Parti Radical Valoisien (PR)
replace party_cmp = 31021 if prtvtcfr == 6   // Front de Gauche (FDG)
replace party_cmp = 31230 if prtvtcfr == 7   // Parti Radical de Gauche (PRG)
replace party_cmp = 31320 if prtvtcfr == 9   // Parti Socialiste (PS)
replace party_cmp = 31626 if prtvtcfr == 10  // UMP
replace party_cmp = 31624 if prtvtcfr == 11  // MoDem
replace party_cmp = 31110 if prtvtcfr == 12  // EELV

merge m:1 party_cmp using `mp_france', keep(match master)

* Check whether it's 9
egen tag_party = tag(party_cmp) if _merge == 3
count if tag_party == 1
display as text "Number of distinct matched parties: " r(N)
drop tag_party
tab partyabbrev_cmp if _merge == 3, missing
drop _merge

save `problem7_e', replace

*---------------------------------------------------*
**# Problem VII(f)
* Regress the corporatism / mixed economy
* score of the voted party on the region-level China shock,
* using both OLS and IV as above.
* Transform the score as: log(.5 + z_pc)
*---------------------------------------------------*

use `problem7_e', clear

* Keep only respondents whose voted party was matched to Manifesto data
keep if !missing(per405)

* Create NUTS1 code from NUTS2 code
capture drop nuts1
gen nuts1 = substr(nuts2, 1, 3)

* Construct transformed corporatism score
capture drop corporatism_score_pc
gen corporatism_score_pc = log(0.5 + per405)

* Quick checks
summarize corporatism_score_pc per405 china_shock china_shock_us

*---------------------------------------------------*
* OLS regression
*---------------------------------------------------*
xi: reg corporatism_score_pc china_shock female agea i.edlvdfr i.nuts1_id ///
    [pweight=pspwght], vce(cluster nuts2_id)
eststo OLS_corporatism

*---------------------------------------------------*
* First stage
*---------------------------------------------------*
xi: reg china_shock china_shock_us female agea i.edlvdfr i.nuts1_id ///
    [pweight=pspwght], vce(cluster nuts2_id)
eststo First_Stage_VIIf

*---------------------------------------------------*
* IV regression
*---------------------------------------------------*
xi: ivreg2 corporatism_score_pc (china_shock = china_shock_us) ///
    female agea i.edlvdfr i.nuts1_id ///
    [pweight=pspwght], cluster(nuts2_id) first
* Disabled alternative specification retained from the definitive source:
* xi: ivreg2 corporatism_score_pc (china_shock = china_shock_us) ///
*     female agea i.edlvdfr i.nuts1_id ///
*     [pweight=pspwght], cluster(nuts2_id) ///
*     partial(female agea i.edlvdfr i.nuts1_id) first

scalar F_KP_f = e(widstat)

* Store IV estimates with ivregress for esttab
xi: ivregress 2sls corporatism_score_pc (china_shock = china_shock_us) ///
    female agea i.edlvdfr i.nuts1_id ///
    [pweight=pspwght], vce(cluster nuts2_id)
eststo IV_corporatism
estadd scalar F_KP_f

*---------------------------------------------------*
* Labels
*---------------------------------------------------*
label var corporatism_score_pc "log(0.5 + corporatism score)"
label var china_shock          "China shock"
label var china_shock_us       "China shock instrument (US-from-China)"

*---------------------------------------------------*
* Export table
*---------------------------------------------------*
esttab OLS_corporatism IV_corporatism First_Stage_VIIf ///
    using "`table_dir'/table_problem7f.tex", replace ///
    keep(china_shock china_shock_us) ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2 F_KP_f, fmt(%9.0fc 3 3) ///
          labels("Observations" "R^2" "Kleibergen-Paap F")) ///
    mtitles("OLS" "2SLS" "First stage") ///
    title("VII(f): China shock and corporatism score of voted party")

save `problem7_f', replace


*---------------------------------------------------*
**# Problem VII(g)
* What can we learn from the above results about the political reactions of workers to globalization? How do these results contribute to characterizing the globalization backlash?
*---------------------------------------------------*
*Answer on the Report

log close
