# Economics of European Integration — Take-Home Assignment

This repository contains the definitive collaborative Stata workflow and the submitted explanatory note for a take-home assignment in **20269 – Economics of European Integration** at Bocconi University.

The analysis connects firm heterogeneity and internationalisation with European regional exposure to Chinese import competition and its political-economy implications. The script covers the submitted computational workflow for Problems I–VII; documented source-to-assignment discrepancies appear under Validation status.

## Contributors and acknowledgements

The original assignment and explanatory note were produced collaboratively by Giorgio Ucropina with:

- Tanjima Tasnim
- Agnese Porro
- Alex Vigna Lobbia
- Andrea Boscolo Meneguolo

No individual responsibilities are assigned here because the submitted materials describe the work collectively.

## Assignment structure and methodology

### Part I — firm productivity, trade, and markups

- **Problem I:** Descriptive comparisons of French and Italian firms in NACE 22 (publishing and printing) and NACE 36 (furniture) in 2007.
- **Problem II:** Cobb–Douglas value-added production functions estimated by OLS, Wooldridge (`prodest`), and Levinsohn–Petrin (`levpet`). The specifications account for the pooled country-year structure through the controls used in the original analysis.
- **Problem III:** Theoretical comparison of revenue- and value-added production functions. This is a written question answered in the explanatory note.
- **Problem IV:** Sector-specific 1st/99th-percentile TFP cleaning; density, skewness, and Pareto-tail analysis; and regressions estimating export, pure-exporter, and FDI productivity premia.
- **Problem V:** Price-cost-margin and De Loecker–Warzynski markup measures, exporter and size regressions, and a productivity-on-markup specification.

### Part II — regional China shock and political outcomes

- **Problem VI(a):** Construction of regional shift-share China shocks from pre-sample employment weights and five-year changes in Chinese imports. The analogous change in US imports from China is constructed as an instrument. The assignment instructions ask for datasets A–C to be merged, but the definitive script explicitly omits dataset C and builds the shock from A, B, and D.
- **Problem VI(b):** Regional averages over 1995–2007. The definitive implementation does not use assignment dataset C.
- **Problem VI(c):** NUTS-2 maps for the average China shock and the 1988 manufacturing-employment share for Spain, France, and Italy.
- **Problem VII(a):** Harmonisation of historical and ESS Round 8 French NUTS-2 codes, followed by a regional-shock merge.
- **Problem VII(b):** Survey-weighted OLS for perceived effects of social benefits on equality (`sbeqsoc`), controlling for gender, age, education, and NUTS-1 fixed effects, with NUTS-2 clustered standard errors.
- **Problem VII(c):** IV/2SLS using the US-China import shock, including the first stage, Kleibergen–Paap statistic, effect-size calculations, and an OLS/IV comparison table.
- **Problem VII(d):** Written economic interpretation, provided in the explanatory note.
- **Problem VII(e):** Matching nine French parties reported in the ESS to 2012 Comparative Manifesto Project party identifiers and the `per405` measure.
- **Problem VII(f):** Survey-weighted OLS and IV estimates for `log(0.5 + per405)`.
- **Problem VII(g):** Written discussion of political reactions to globalisation, provided in the explanatory note.

## Main empirical findings

The following results are reported in the explanatory note and were not independently recomputed during repository preparation:

- In sector 22, estimated labour elasticities are 0.415 (OLS), 0.501 (Wooldridge), and 0.362 (LP); in sector 36 they are 0.417, 0.363, and 0.320. The report discusses simultaneity and endogenous input choice when interpreting these differences.
- Mean WRDG TFP in French sector 22 rises from 110.72 in 2001 to 142.79 in 2007, while the corresponding Italian mean changes from 117.52 to 118.96. Changes in the estimated Pareto slopes indicate non-uniform distributional shifts.
- The all-exporter and pure-exporter log-productivity premia are 0.0903 and 0.0865. Reported FDI comparisons are larger, ranging from 0.146 to 0.226 depending on the comparison group.
- Mean markups are 1.68 using PCM and 1.54 using DLW. The exporter coefficient is 0.214 without firm size and 0.188 with size; the reported TFP-on-markup coefficient is 0.1907.
- Baseline manufacturing shares broadly align with regional China-shock exposure, although industrial composition also matters.
- For the French ESS sample, the China-shock coefficient for `sbeqsoc` is −0.796 in OLS (`p` = 0.039) and −0.781 in IV (`p` = 0.030). The corporatism-score estimates are 0.396 in OLS and 0.404 in IV. The report interprets the findings through compensation and embedded-liberalism mechanisms while noting the limited number of regional clusters.

## Repository structure

```text
.
├── .gitignore
├── README.md
├── code_takehome.do
├── explanatory_note.pdf
└── data/
    └── README.md
```

- [`code_takehome.do`](code_takehome.do) is the single authoritative, portability-adjusted Stata script for Problems I–VII.
- [`explanatory_note.pdf`](explanatory_note.pdf) is the unchanged collaborative report.
- [`data/README.md`](data/README.md) lists every external input and its expected path.
- `outputs/` is created when the script runs and is intentionally ignored by Git.

## Data availability

No data are distributed in this repository. The course-provided firm, trade, employment, and geographic inputs have unresolved redistribution terms; ESS and Comparative Manifesto Project data must be obtained under their respective access conditions.

The full script expects these external inputs under `data/`:

```text
data/
├── EEI_TH_P1_2026.dta
├── Employment_Shares_Take_Home.dta
├── Imports_China_Take_Home.dta
├── Imports_US_China_Take_Home.dta
├── ESS8e02_3.dta
├── MPDataset_MPDS2025a.dta
├── NUTS_RG_20M_2013_3035.shp
├── NUTS_RG_20M_2013_3035.shx
├── NUTS_RG_20M_2013_3035.dbf
├── NUTS_RG_20M_2013_3035.prj
└── NUTS_RG_20M_2013_3035.cpg
```

The first four datasets and the geographic bundle were located in the original assignment folder. `ESS8e02_3.dta` and `MPDataset_MPDS2025a.dta` were not located and must be supplied by an authorised user. See the data guide for variables, provenance, and generated intermediates.

## Software and Stata packages

The final `table ... statistic()` command requires Stata 17 or later. The script also uses these user-written commands:

- `outreg2`
- `esttab`, `eststo`, and `estadd` from `estout`
- `prodest`
- `levpet` and its dependencies
- `grc1leg`
- `spmap`
- `shp2dta`
- `ivreg2`
- `ranktest`

Install packages deliberately from trusted Stata sources before running the script. Typical commands are:

```stata
ssc install outreg2
ssc install estout
ssc install grc1leg
ssc install spmap
ssc install shp2dta
ssc install ivreg2
ssc install ranktest
search prodest
search levpet
```

Review the `search` results and install the required `prodest` and `levpet` packages and dependencies. The do-file checks command availability but never installs packages automatically.

## Reproducing the analysis

1. Clone or download this repository.
2. Obtain authorised copies of the inputs documented in [`data/README.md`](data/README.md) and place them directly under `data/` with the exact filenames shown above.
3. Start Stata and change the working directory to the repository root. The script does not assume that Stata automatically uses the do-file’s directory:

   ```stata
   cd "path/to/20269-economics-of-european-integration-ps"
   do "code_takehome.do"
   ```

4. Generated files appear under:

   ```text
   outputs/
   ├── figures/
   ├── intermediate/
   ├── logs/
   ├── maps/
   └── tables/
   ```

The script reads but never overwrites external inputs. Most analytical intermediates use Stata `tempfile` objects; shapefile conversions and merged map databases are placed under `outputs/intermediate/`.

## Source-code provenance and portability changes

The repository script is adapted from the definitive collaborative `code_takehome.do` recovered after the initial repository version was created. It supersedes the earlier partial PDF-based reconstruction and is not derived from the unrelated Graziosi prior-year project.

Portability adjustments are limited to:

- replacing all username- and machine-specific working directories with documented relative paths;
- separating external inputs (`data/`) from generated outputs (`outputs/`);
- using temporary files for analytical intermediates where practical;
- adding input and package checks without automatic installation;
- directing logs, tables, graphs, and maps to predictable subdirectories;
- adding a concise execution header and full-name contributor acknowledgement;
- completing the output destination for the Problem VII(c) table;
- fully commenting three disabled multiline diagnostics/specifications whose first lines alone were commented in the definitive source, which otherwise left invalid continuation lines executable.

No sample restriction, variable definition, estimator, control set, instrument, weighting choice, clustering level, or active model specification was changed.

## Validation status

Stata was not installed or discoverable during repository preparation. The complete script was therefore not executed, and numerical reproducibility remains unverified.

Static validation included:

- matching every computational question in Problems I–VII to the definitive script;
- comparing the portability-adjusted script against the definitive source;
- auditing all input, intermediate, output, and map paths;
- checking macro lifetimes across Parts I and II;
- checking balanced braces, `preserve`/`restore` pairs, and multiline continuations;
- inspecting available Stata datasets and geographic companions;
- comparing the implemented models and reported findings with the assignment instructions and explanatory note.

Execution still requires a licensed Stata installation, all documented packages, and the two external Problem VII datasets that were not found locally.

### Known source-to-assignment discrepancies

- Problem VI(a) instructs students to merge datasets A–C. The definitive source instead states “dataset C not used” and never reads `EEI_TH_P6_2026.dta`. The repository preserves that implementation and does not invent a merge or downstream use for dataset C.
- The explanatory note reports an Anderson–Rubin Wald test for Problem VII(c), but no command computing that test appears in the definitive source. The reported result remains part of the note, not a reproducible output of this do-file.
- The explanatory note mentions a robustness check using three broader education groups for Problem VII(f); the definitive source does not contain that robustness specification.

## Publication and rights

Assignment instructions, the original non-portable source, datasets, shapefiles, and generated results are not tracked. Their omission avoids publishing course or third-party material with uncertain redistribution rights.

No open-source or data licence is asserted. Reuse remains subject to the rights of the collaborators, course staff, and original data providers. Confirm collaborator consent before publicly distributing the jointly authored explanatory note.
