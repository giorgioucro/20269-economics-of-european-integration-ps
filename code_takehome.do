*===============================================================================
*
*                    Economics of European Integration
*                         Final Report 2025/2026
*
* Course:       20269 Economics of European Integration
* Institution:  Bocconi University
* Authors:      Tanjima Tasnim, Agnese Porro, Alex Vigna Lobbia,
*               Andrea Boscolo Meneguolo, Giorgio Ucropina
* Date:         March 2026
*
* Reconstruction note:
*   This portable file was reconstructed from code_takehome.pdf. The available
*   listing contains Part I (Problems I-V) only. The explanatory note reports
*   Problems VI-VII, but their matching source commands were not available.
*
* Required software:
*   Stata plus outreg2, esttab (estout), prodest, levpet, and grc1leg.
* Required dataset:
*   Authorised copy of data/EEI_TH_P1_2026.dta.
* Working directory and outputs:
*   Run this file from the repository root. Generated tables, figures,
*   intermediate data, and the text log are written below output/.
*===============================================================================

clear all
set more off
capture log close

local data_file        "data/EEI_TH_P1_2026.dta"
local figure_dir       "output/figures"
local table_dir        "output/tables"
local intermediate_dir "output/intermediate"
local log_dir          "output/logs"

capture mkdir "output"
capture mkdir "`figure_dir'"
capture mkdir "`table_dir'"
capture mkdir "`intermediate_dir'"
capture mkdir "`log_dir'"

capture confirm file "`data_file'"
if _rc {
    display as error "Required input not found: `data_file'"
    display as error "Set Stata's working directory to the repository root and see data/README.md."
    exit 601
}

local missing_command 0
foreach command in outreg2 esttab prodest levpet grc1leg {
    capture which `command'
    if _rc {
        display as error "Required user-written command is not installed: `command'"
        local missing_command 1
    }
}
if `missing_command' {
    display as error "Install the missing commands from trusted Stata sources, then rerun."
    exit 199
}

log using "`log_dir'/take_home_2026_part1.log", text replace
use "`data_file'", clear

*******************************************************************************
* Variables for production-function estimation
*******************************************************************************

foreach var in real_VA real_sales real_K real_M L {
    gen ln_`var' = .
    replace ln_`var' = ln(`var') if `var' > 0
}

*******************************************************************************
**# Problem I
* Descriptive statistics for France and Italy in NACE 22 and 36, 2007
*******************************************************************************

preserve
    keep if year == 2007 & inlist(nace, 22, 36) & inlist(country, "FRA", "ITA")

    ***************************************************************************
    * TABLE 1: FRANCE - continuous variables
    ***************************************************************************
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

        quietly summarize `v' if country == "FRA" & nace == 22, detail
        local n1   : display %9.0f r(N)
        local m1   : display %9.2f r(mean)
        local p501 : display %9.2f r(p50)
        local p251 : display %9.2f r(p25)
        local p751 : display %9.2f r(p75)

        quietly summarize `v' if country == "FRA" & nace == 36, detail
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

    ***************************************************************************
    * TABLE 2: FRANCE - exporter and FDI counts
    ***************************************************************************
    capture erase "`table_dir'/table_problem1_fra_status.tex"
    file open tfra2 using "`table_dir'/table_problem1_fra_status.tex", write text replace

    quietly count if country == "FRA" & nace == 22
    local n22 = r(N)
    quietly count if country == "FRA" & nace == 36
    local n36 = r(N)
    quietly count if country == "FRA" & nace == 22 & exporter == 1
    local exp22 = r(N)
    quietly count if country == "FRA" & nace == 36 & exporter == 1
    local exp36 = r(N)
    quietly count if country == "FRA" & nace == 22 & FDI == 1
    local fdi22 = r(N)
    quietly count if country == "FRA" & nace == 36 & FDI == 1
    local fdi36 = r(N)

    local expshare22 : display %9.2f (`exp22'/`n22') * 100
    local expshare36 : display %9.2f (`exp36'/`n36') * 100
    local fdishare22 : display %9.2f (`fdi22'/`n22') * 100
    local fdishare36 : display %9.2f (`fdi36'/`n36') * 100

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

    ***************************************************************************
    * TABLE 3: ITALY - continuous variables
    ***************************************************************************
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

        quietly summarize `v' if country == "ITA" & nace == 22, detail
        local n1   : display %9.0f r(N)
        local m1   : display %9.2f r(mean)
        local p501 : display %9.2f r(p50)
        local p251 : display %9.2f r(p25)
        local p751 : display %9.2f r(p75)

        quietly summarize `v' if country == "ITA" & nace == 36, detail
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

    ***************************************************************************
    * TABLE 4: ITALY - exporter and FDI counts
    ***************************************************************************
    capture erase "`table_dir'/table_problem1_ita_status.tex"
    file open tita2 using "`table_dir'/table_problem1_ita_status.tex", write text replace

    quietly count if country == "ITA" & nace == 22
    local n22 = r(N)
    quietly count if country == "ITA" & nace == 36
    local n36 = r(N)
    quietly count if country == "ITA" & nace == 22 & exporter == 1
    local exp22 = r(N)
    quietly count if country == "ITA" & nace == 36 & exporter == 1
    local exp36 = r(N)
    quietly count if country == "ITA" & nace == 22 & FDI == 1
    local fdi22 = r(N)
    quietly count if country == "ITA" & nace == 36 & FDI == 1
    local fdi36 = r(N)

    local expshare22 : display %9.2f (`exp22'/`n22') * 100
    local expshare36 : display %9.2f (`exp36'/`n36') * 100
    local fdishare22 : display %9.2f (`fdi22'/`n22') * 100
    local fdishare36 : display %9.2f (`fdi36'/`n36') * 100

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

* FRA36 has only 16 firms. Its much higher mean capital, sales, employment,
* and value added should be interpreted cautiously; median gaps are smaller.
* Sample sizes vary because some balance-sheet items are missing.

*******************************************************************************
**# Problem II
* Production-function estimates: OLS, Wooldridge, Levinsohn-Petrin
*******************************************************************************

preserve
    keep if nace == 22 | nace == 36
    xtset mark year

    * Sector 22: OLS
    xi: reg ln_real_VA ln_L ln_real_K i.country i.year if nace == 22
    estimates store ols_22

    * Sector 22: WRDG
    xi: prodest ln_real_VA if nace == 22, ///
        met(wrdg) ///
        free(ln_L) ///
        proxy(ln_real_M) ///
        state(ln_real_K) ///
        va
    estimates store wrdg_22

    * Sector 22: LP
    set seed 12345
    xi: levpet ln_real_VA if nace == 22, ///
        free(ln_L i.country i.year) ///
        proxy(ln_real_M) ///
        capital(ln_real_K) ///
        reps(50) level(99) va
    estimates store lp_22

    * Sector 36: OLS
    xi: reg ln_real_VA ln_L ln_real_K i.country i.year if nace == 36
    estimates store ols_36

    * Sector 36: WRDG
    xi: prodest ln_real_VA if nace == 36, ///
        met(wrdg) ///
        free(ln_L) ///
        proxy(ln_real_M) ///
        state(ln_real_K) ///
        va
    estimates store wrdg_36

    * Sector 36: LP
    set seed 67890
    xi: levpet ln_real_VA if nace == 36, ///
        free(ln_L i.country i.year) ///
        proxy(ln_real_M) ///
        capital(ln_real_K) ///
        reps(50) level(99) va
    estimates store lp_36
restore

* levpet uses bootstrap repetitions for standard errors. Fixed seeds make the
* two Problem II LP estimates reproducible.

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

*******************************************************************************
**# Problem III
* The revenue-versus-value-added discussion is presented in explanatory_note.pdf.
*******************************************************************************

*******************************************************************************
**# Problem IV
* Define TFP and clear sector-specific 1st/99th-percentile extremes
*******************************************************************************

* OLS TFP: sector 22
xi: reg ln_real_VA ln_L ln_real_K i.country i.year if nace == 22
predict ln_TFP_OLS_22, residuals
gen TFP_OLS_22 = exp(ln_TFP_OLS_22)

* OLS TFP: sector 36
xi: reg ln_real_VA ln_L ln_real_K i.country i.year if nace == 36
predict ln_TFP_OLS_36, residuals
gen TFP_OLS_36 = exp(ln_TFP_OLS_36)

* Wooldridge TFP: sector 22
xi: prodest ln_real_VA if nace == 22, ///
    met(wrdg) ///
    free(ln_L) ///
    proxy(ln_real_M) ///
    state(ln_real_K) ///
    va
predict ln_TFP_WRDG_22, resid
gen TFP_WRDG_22 = exp(ln_TFP_WRDG_22)

* Wooldridge TFP: sector 36
xi: prodest ln_real_VA if nace == 36, ///
    met(wrdg) ///
    free(ln_L) ///
    proxy(ln_real_M) ///
    state(ln_real_K) ///
    va
predict ln_TFP_WRDG_36, resid
gen TFP_WRDG_36 = exp(ln_TFP_WRDG_36)

* Levinsohn-Petrin TFP: sector 22
xi: levpet ln_real_VA if nace == 22, ///
    free(ln_L i.country i.year) ///
    proxy(ln_real_M) ///
    capital(ln_real_K) ///
    reps(20) level(99) va
predict TFP_LP_22, omega

* Levinsohn-Petrin TFP: sector 36
xi: levpet ln_real_VA if nace == 36, ///
    free(ln_L i.country i.year) ///
    proxy(ln_real_M) ///
    capital(ln_real_K) ///
    reps(20) level(99) va
predict TFP_LP_36, omega

* Clear WRDG extremes within sector.
foreach s in 22 36 {
    summarize TFP_WRDG_`s' if nace == `s', detail
    replace TFP_WRDG_`s' = . if !inrange(TFP_WRDG_`s', r(p1), r(p99)) & nace == `s'
}
gen TFP_WRDG = .
replace TFP_WRDG = TFP_WRDG_22 if nace == 22
replace TFP_WRDG = TFP_WRDG_36 if nace == 36
gen ln_TFP_WRDG = ln(TFP_WRDG)

* Clear LP extremes within sector.
foreach s in 22 36 {
    summarize TFP_LP_`s' if nace == `s', detail
    replace TFP_LP_`s' = . if !inrange(TFP_LP_`s', r(p1), r(p99)) & nace == `s'
}
gen TFP_LP = .
replace TFP_LP = TFP_LP_22 if nace == 22
replace TFP_LP = TFP_LP_36 if nace == 36
gen ln_TFP_LP = ln(TFP_LP)

capture drop _Icountry_2 _Iyear_2002 _Iyear_2003 _Iyear_2004 _Iyear_2005 ///
    _Iyear_2006 _Iyear_2007 _Iyear_2008 _Iyear_2009

*******************************************************************************
* Problem IV(a): graphs used in the explanatory note
*******************************************************************************

twoway ///
    (kdensity TFP_WRDG if nace == 22, lcolor(sienna)) ///
    (kdensity TFP_WRDG if nace == 36, lcolor(black)), ///
    title("TFP Densities with WRDG") legend(off) name(wrdg_lev, replace)

twoway ///
    (kdensity ln_TFP_WRDG if nace == 22, lcolor(sienna)) ///
    (kdensity ln_TFP_WRDG if nace == 36, lcolor(black)), ///
    title("Log-TFP Densities with WRDG") legend(off) name(wrdg_log, replace)

twoway ///
    (kdensity TFP_LP if nace == 22, lcolor(sienna)) ///
    (kdensity TFP_LP if nace == 36, lcolor(black)), ///
    title("TFP Densities with LP") legend(off) name(lp_lev, replace)

twoway ///
    (kdensity ln_TFP_LP if nace == 22, lcolor(sienna)) ///
    (kdensity ln_TFP_LP if nace == 36, lcolor(black)), ///
    title("Log-TFP Densities with LP") ///
    legend(label(1 "Sector 22") label(2 "Sector 36")) ///
    name(lp_log, replace)

grc1leg wrdg_lev wrdg_log lp_lev lp_log, ///
    cols(2) imargin(tiny) legendfrom(lp_log) ///
    title("TFP densities by estimator and transformation") ///
    name(fig_problem4a, replace)
graph export "`figure_dir'/figure_problem4a.pdf", replace

* TFP in levels, separate by sector and estimator.
twoway (kdensity TFP_WRDG if nace == 22, lcolor(sienna) lwidth(medthick)), ///
    title("Sector 22") legend(off) graphregion(color(white)) ///
    name(wrdg_lev_22, replace)
twoway (kdensity TFP_WRDG if nace == 36, lcolor(black) lwidth(medthick)), ///
    title("Sector 36") legend(off) graphregion(color(white)) ///
    name(wrdg_lev_36, replace)
graph combine wrdg_lev_22 wrdg_lev_36, cols(2) ///
    title("TFP distributions with WRDG") name(g_wrdg_lev, replace)

twoway (kdensity TFP_LP if nace == 22, lcolor(sienna) lwidth(medthick)), ///
    title("Sector 22") legend(off) graphregion(color(white)) ///
    name(lp_lev_22, replace)
twoway (kdensity TFP_LP if nace == 36, lcolor(black) lwidth(medthick)), ///
    title("Sector 36") legend(off) graphregion(color(white)) ///
    name(lp_lev_36, replace)
graph combine lp_lev_22 lp_lev_36, cols(2) ///
    title("TFP distributions with LP") name(g_lp_lev, replace)
graph combine g_wrdg_lev g_lp_lev, cols(1) imargin(tiny) ///
    title("TFP densities by estimator") name(fig_problem4a_levels, replace)
graph export "`figure_dir'/figure_problem4a_TFP_estim.pdf", replace

* Log-TFP, separate by sector and estimator.
twoway (kdensity ln_TFP_WRDG if nace == 22, lcolor(sienna) lwidth(medthick)), ///
    title("Sector 22") legend(off) graphregion(color(white)) ///
    name(wrdg_log_22, replace)
twoway (kdensity ln_TFP_WRDG if nace == 36, lcolor(black) lwidth(medthick)), ///
    title("Sector 36") legend(off) graphregion(color(white)) ///
    name(wrdg_log_36, replace)
graph combine wrdg_log_22 wrdg_log_36, cols(2) ///
    title("Log-TFP distributions with WRDG") name(g_wrdg_log, replace)

twoway (kdensity ln_TFP_LP if nace == 22, lcolor(sienna) lwidth(medthick)), ///
    title("Sector 22") legend(off) graphregion(color(white)) ///
    name(lp_log_22, replace)
twoway (kdensity ln_TFP_LP if nace == 36, lcolor(black) lwidth(medthick)), ///
    title("Sector 36") legend(off) graphregion(color(white)) ///
    name(lp_log_36, replace)
graph combine lp_log_22 lp_log_36, cols(2) ///
    title("Log-TFP distributions with LP") name(g_lp_log, replace)
graph combine g_wrdg_log g_lp_log, cols(1) imargin(tiny) ///
    title("Log-TFP densities by estimator") name(fig_problem4a_log, replace)
graph export "`figure_dir'/Q4a_log_TFP_estim.pdf", replace

* Country-specific log-WRDG densities by sector.
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
        xtitle("log TFP (WRDG)") ytitle("Density") ///
        legend(order(1 "France" 2 "Italy")) ///
        graphregion(color(white)) name(g22_country, replace)

    twoway ///
        (kdensity ln_TFP_WRDG if country == "FRA" & nace == 36, ///
            lcolor(navy) lwidth(medthick)) ///
        (kdensity ln_TFP_WRDG if country == "ITA" & nace == 36, ///
            lcolor(maroon) lwidth(medthick) lpattern(dash)), ///
        title("Sector 36: log-WRDG TFP by country") ///
        subtitle("France (N=`N_FRA36') vs Italy (N=`N_ITA36')") ///
        xtitle("log TFP (WRDG)") ytitle("Density") ///
        legend(order(1 "France" 2 "Italy")) ///
        graphregion(color(white)) name(g36_country, replace)

    graph combine g22_country g36_country, cols(1) ///
        title("Country-specific log-WRDG TFP distributions by sector") ///
        graphregion(color(white)) name(g_country_wrdg, replace)
    graph export "`figure_dir'/Q4a_WRDG_country_split.pdf", replace
restore

* Four country-sector WRDG panels.
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

    twoway (kdensity ln_TFP_WRDG if country == "FRA" & nace == 22, ///
        lcolor(navy) lwidth(medthick)), ///
        title("France, sector 22 (N=`N_FRA22')") ///
        xtitle("log TFP (WRDG)") ytitle("Density") legend(off) ///
        graphregion(color(white)) name(g_fra22, replace)

    twoway (kdensity ln_TFP_WRDG if country == "ITA" & nace == 22, ///
        lcolor(maroon) lwidth(medthick)), ///
        title("Italy, sector 22 (N=`N_ITA22')") ///
        xtitle("log TFP (WRDG)") ytitle("Density") legend(off) ///
        graphregion(color(white)) name(g_ita22, replace)

    twoway (kdensity ln_TFP_WRDG if country == "FRA" & nace == 36, ///
        lcolor(navy) lwidth(medthick)), ///
        title("France, sector 36 (N=`N_FRA36')") ///
        xtitle("log TFP (WRDG)") ytitle("Density") legend(off) ///
        graphregion(color(white)) name(g_fra36, replace)

    twoway (kdensity ln_TFP_WRDG if country == "ITA" & nace == 36, ///
        lcolor(maroon) lwidth(medthick)), ///
        title("Italy, sector 36 (N=`N_ITA36')") ///
        xtitle("log TFP (WRDG)") ytitle("Density") legend(off) ///
        graphregion(color(white)) name(g_ita36, replace)

    graph combine g_fra22 g_ita22 g_fra36 g_ita36, cols(2) ///
        title("Country- and sector-specific log-WRDG TFP densities") ///
        graphregion(color(white)) name(g_wrdg_4panels, replace)
    graph export "`figure_dir'/Q4a_WRDG_4panels.pdf", replace
restore

save "`intermediate_dir'/EEI_TH_P1_2026_cleaned_sample.dta", replace

*******************************************************************************
* Problem IV(b): sector 22 WRDG TFP in France and Italy, 2001 versus 2007
*******************************************************************************

use "`intermediate_dir'/EEI_TH_P1_2026_cleaned_sample.dta", clear

preserve
    keep if nace == 22 & inlist(country, "FRA", "ITA")

    twoway ///
        (kdensity TFP_WRDG if country == "FRA" & year == 2001, ///
            lcolor(navy) lwidth(medthick)) ///
        (kdensity TFP_WRDG if country == "FRA" & year == 2007, ///
            lcolor(orange) lwidth(medthick) lpattern(dash)), ///
        title("WRDG TFP - Sector 22, France") ///
        xtitle("TFP (WRDG)") ytitle("Density") ///
        legend(label(1 "2001") label(2 "2007"))
    graph save "`figure_dir'/Q4b_WRDG_FRA.gph", replace
    graph export "`figure_dir'/Q4b_WRDG_FRA.png", replace

    twoway ///
        (kdensity TFP_WRDG if country == "ITA" & year == 2001, ///
            lcolor(navy) lwidth(medthick)) ///
        (kdensity TFP_WRDG if country == "ITA" & year == 2007, ///
            lcolor(orange) lwidth(medthick) lpattern(dash)), ///
        title("WRDG TFP - Sector 22, Italy") ///
        xtitle("TFP (WRDG)") ytitle("Density") ///
        legend(label(1 "2001") label(2 "2007"))
    graph save "`figure_dir'/Q4b_WRDG_ITA.gph", replace
    graph export "`figure_dir'/Q4b_WRDG_ITA.png", replace

    graph combine "`figure_dir'/Q4b_WRDG_FRA.gph" ///
        "`figure_dir'/Q4b_WRDG_ITA.gph", ///
        title("WRDG TFP Distributions - Sector 22 (2001 vs 2007)")
    graph export "`figure_dir'/Q4b_combined.png", replace

    foreach ctry in FRA ITA {
        foreach yr in 2001 2007 {
            quietly summarize TFP_WRDG if country == "`ctry'" & year == `yr', detail
            display "Country: `ctry' Year: `yr'"
            display " N = " r(N)
            display " Mean = " r(mean)
            display " Median = " r(p50)
            display " Std dev = " r(sd)
            display " Skewness = " r(skewness)
            display " Kurtosis = " r(kurtosis)
        }
    }
restore

*******************************************************************************
* Problem IV(c): Pareto-tail regressions
*******************************************************************************

preserve
    keep if nace == 22 & inlist(country, "FRA", "ITA")
    sort country year TFP_WRDG
    by country year: cumul TFP_WRDG, generate(cum_TFP_WRDG)
    gen rhs_WRDG = log(1 - cum_TFP_WRDG) if cum_TFP_WRDG < 1

    quietly reg rhs_WRDG ln_TFP_WRDG if country == "FRA"
    outreg2 using "`table_dir'/Pareto_FRA_22.tex", replace tex ///
        title("Pareto Distribution - France, Sector 22") ctitle("All years")
    quietly reg rhs_WRDG ln_TFP_WRDG if country == "FRA" & year == 2001
    outreg2 using "`table_dir'/Pareto_FRA_22.tex", append tex ctitle("2001")
    quietly reg rhs_WRDG ln_TFP_WRDG if country == "FRA" & year == 2007
    outreg2 using "`table_dir'/Pareto_FRA_22.tex", append tex ctitle("2007")

    quietly reg rhs_WRDG ln_TFP_WRDG if country == "ITA"
    outreg2 using "`table_dir'/Pareto_ITA_22.tex", replace tex ///
        title("Pareto Distribution - Italy, Sector 22") ctitle("All years")
    quietly reg rhs_WRDG ln_TFP_WRDG if country == "ITA" & year == 2001
    outreg2 using "`table_dir'/Pareto_ITA_22.tex", append tex ctitle("2001")
    quietly reg rhs_WRDG ln_TFP_WRDG if country == "ITA" & year == 2007
    outreg2 using "`table_dir'/Pareto_ITA_22.tex", append tex ctitle("2007")

    foreach ctry in FRA ITA {
        foreach yr in 2001 2007 {
            quietly reg rhs_WRDG ln_TFP_WRDG if country == "`ctry'" & year == `yr'
            display "Pareto slope | Country: `ctry' Year: `yr' -> beta = " ///
                _b[ln_TFP_WRDG] " (se = " _se[ln_TFP_WRDG] ")"
        }
    }
restore

*******************************************************************************
* Problem IV(d): export, pure-exporter, and FDI/multinational premia
*******************************************************************************

capture drop export_status
gen export_status = .
replace export_status = 0 if exporter == 0 & FDI == 0
replace export_status = 1 if exporter == 1 & FDI == 0
replace export_status = 2 if exporter == 1 & FDI == 1

* FDI == 1 and exporter == 0 is outside this three-way classification.
tab export_status, missing
tab export_status if !missing(ln_TFP_LP), missing
tab country nace if !missing(ln_TFP_LP) & export_status == 0, missing
tab country nace if !missing(ln_TFP_LP) & export_status == 1, missing
tab country nace if !missing(ln_TFP_LP) & export_status == 2, missing

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

tabstat ln_TFP_LP if inlist(export_status, 0, 1, 2), ///
    by(nace) stat(mean median sd n)

twoway ///
    (kdensity ln_TFP_LP if export_status == 2, lw(medthick) lcolor(green)) ///
    (kdensity ln_TFP_LP if export_status == 1, lw(medthin) lcolor(sienna)) ///
    (kdensity ln_TFP_LP if export_status == 0, lw(medthin) lcolor(blue) lp(dash)), ///
    title("LP TFP distributions by export status") ///
    xtitle("log TFP (LP)") ytitle("Density") ///
    legend(label(1 "Multinationals (Exporters + FDI)") ///
        label(2 "Pure exporters") label(3 "Domestic only"))
graph export "`figure_dir'/Q4d_TFP_by_status.png", replace

* All exporters versus non-exporters.
xi: reg ln_TFP_LP exporter i.year i.nace i.country ///
    if inlist(export_status, 0, 1, 2), robust
estimates store all_export_premium
outreg2 using "`table_dir'/table_Q4d_premium.tex", replace ///
    title("Export and FDI Premium") ctitle("All exporters") ///
    addtext(Year FE, YES, Sector FE, YES, Country FE, YES) ///
    drop(_Iyear* _Inace* _Icountry*)

* Pure exporters versus domestic firms.
xi: reg ln_TFP_LP exporter i.year i.nace i.country ///
    if export_status == 0 | export_status == 1, robust
estimates store pure_export_premium
outreg2 using "`table_dir'/table_Q4d_premium.tex", append ///
    ctitle("Pure exporters") ///
    addtext(Year FE, YES, Sector FE, YES, Country FE, YES) ///
    drop(_Iyear* _Inace* _Icountry*)

* Exporters with FDI versus domestic firms.
xi: reg ln_TFP_LP FDI i.year i.nace i.country ///
    if export_status == 0 | export_status == 2, robust
estimates store fdi_premium
outreg2 using "`table_dir'/table_Q4d_premium.tex", append ///
    ctitle("FDI premium") ///
    addtext(Year FE, YES, Sector FE, YES, Country FE, YES) ///
    drop(_Iyear* _Inace* _Icountry*)

* Exporters with FDI versus pure exporters.
xi: reg ln_TFP_LP FDI i.year i.nace i.country ///
    if export_status == 1 | export_status == 2, robust
estimates store fdi_vs_exporter_premium
outreg2 using "`table_dir'/table_Q4d_premium.tex", append ///
    ctitle("FDI vs exporters") ///
    addtext(Year FE, YES, Sector FE, YES, Country FE, YES) ///
    drop(_Iyear* _Inace* _Icountry*)

* Multinationals versus all non-FDI firms.
xi: reg ln_TFP_LP FDI i.year i.nace i.country ///
    if inlist(export_status, 0, 1, 2), robust
estimates store fdi_vs_all_nonfdi
outreg2 using "`table_dir'/table_Q4d_premium.tex", append ///
    ctitle("FDI vs non-FDI") ///
    addtext(Year FE, YES, Sector FE, YES, Country FE, YES) ///
    drop(_Iyear* _Inace* _Icountry*)

*******************************************************************************
**# Problem V
* PCM and De Loecker-Warzynski markup estimation
*******************************************************************************

use "`intermediate_dir'/EEI_TH_P1_2026_cleaned_sample.dta", clear

* Recover beta_L from LP for each sector.
xi: levpet ln_real_VA if nace == 22, ///
    free(ln_L i.country i.year) ///
    proxy(ln_real_M) ///
    capital(ln_real_K) ///
    reps(50) level(99) va
scalar beta_L_22 = _b[ln_L]
display "beta_L sector 22 (LP) = " beta_L_22

xi: levpet ln_real_VA if nace == 36, ///
    free(ln_L i.country i.year) ///
    proxy(ln_real_M) ///
    capital(ln_real_K) ///
    reps(50) level(99) va
scalar beta_L_36 = _b[ln_L]
display "beta_L sector 36 (LP) = " beta_L_36

* PCM = (sales - wages - materials) / sales.
capture drop PCM markup_PCM alpha_L markup_DLW
gen PCM = (sales - M - W) / sales if sales > 0
summarize PCM, detail
replace PCM = . if !inrange(PCM, r(p1), r(p99))
gen markup_PCM = 1 / (1 - PCM) if PCM < 1

* DLW markup: output elasticity of labour divided by labour's revenue share.
gen alpha_L = W / sales if sales > 0 & W >= 0
gen markup_DLW = .
replace markup_DLW = beta_L_22 / alpha_L if nace == 22 & alpha_L > 0
replace markup_DLW = beta_L_36 / alpha_L if nace == 36 & alpha_L > 0
foreach s in 22 36 {
    summarize markup_DLW if nace == `s', detail
    replace markup_DLW = . if !inrange(markup_DLW, r(p1), r(p99)) & nace == `s'
}

kdensity PCM
twoway ///
    (kdensity markup_DLW, lcolor(green) lwidth(medthick)) ///
    (kdensity markup_PCM, lcolor(sienna) lwidth(medthick)), ///
    title("DLW markup vs PCM") ///
    xtitle("Markup") ytitle("Density") ///
    legend(label(1 "DLW markup") label(2 "PCM markup"))
graph export "`figure_dir'/Q5a_markup_DLW_vs_PCM.png", replace

* Markup differences can reflect heterogeneous market power and incomplete
* pass-through of productivity gains, not productivity alone.
tabstat markup_PCM markup_DLW, stat(mean median p25 p75 sd) columns(statistics)
gen markup_gap = markup_PCM - markup_DLW
tabstat markup_gap, by(nace) stat(mean median sd n)

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

twoway ///
    (kdensity markup_DLW if nace == 22, lcolor(sienna)) ///
    (kdensity markup_DLW if nace == 36, lcolor(black)), ///
    title("DLW markup by sector") ///
    legend(label(1 "Sector 22") label(2 "Sector 36"))

twoway ///
    (kdensity markup_PCM if nace == 22, lcolor(sienna)) ///
    (kdensity markup_PCM if nace == 36, lcolor(black)), ///
    title("PCM markup by sector") ///
    legend(label(1 "Sector 22") label(2 "Sector 36"))

tabstat markup_gap, by(nace) stat(mean median)
tabstat markup_gap, by(country) stat(mean median)
egen country_nace = group(country nace), label
tabstat markup_gap, by(year) stat(mean median)
tabstat markup_gap, by(country_nace) stat(mean median)
tabstat markup_DLW markup_PCM alpha_L, by(country_nace) stat(mean)

*******************************************************************************
* Problem V(b): exporters, DLW markups, and productivity
*******************************************************************************

reg markup_DLW exporter i.year i.nace, robust
estimates store q5b_1
reg markup_DLW exporter ln_L i.year i.nace, robust
estimates store q5b_2
reg ln_TFP_WRDG markup_DLW i.year i.nace, robust
estimates store q5b_3

reg markup_DLW exporter i.year i.nace, robust
outreg2 using "`table_dir'/table_problem5b.tex", replace tex ///
    ctitle("Markup: no size") addtext(Year FE, YES, Sector FE, YES)

reg markup_DLW exporter ln_L i.year i.nace, robust
outreg2 using "`table_dir'/table_problem5b.tex", append tex ///
    ctitle("Markup: + size") addtext(Year FE, YES, Sector FE, YES)

reg ln_TFP_WRDG markup_DLW i.year i.nace, robust
outreg2 using "`table_dir'/table_problem5b.tex", append tex ///
    ctitle("TFP on markup") addtext(Year FE, YES, Sector FE, YES)

*******************************************************************************
* Appendix checks
*******************************************************************************

describe ln_TFP_LP country nace
capture confirm variable country_nace
if _rc {
    egen country_nace = group(country nace), label
}

tabstat ln_TFP_LP if inlist(country, "FRA", "ITA") & inlist(nace, 22, 36), ///
    by(country_nace) stat(mean median sd n)
tabstat ln_TFP_LP if inlist(nace, 22, 36), ///
    by(nace) stat(mean median sd n)
table country nace, ///
    statistic(count ln_TFP_LP) ///
    statistic(mean ln_TFP_LP) ///
    statistic(median ln_TFP_LP) ///
    statistic(sd ln_TFP_LP)

log close
