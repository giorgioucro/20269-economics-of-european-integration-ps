# Economics of European Integration — Problem Set

This repository contains the final explanatory note and the recoverable analysis code for the 2025/2026 take-home assignment in **20269 – Economics of European Integration** at Bocconi University.

The project studies firm productivity, export and FDI premia, markups, regional exposure to Chinese import competition, and related political-economy outcomes. The submitted explanatory note covers Problems I–VII. The available source-code PDF, however, contains executable Stata code only for **Part I (Problems I–V)**. This repository preserves that boundary rather than reconstructing missing Part II code from unrelated material.

## Authors and acknowledgements

Giorgio Ucropina acknowledges the work of his collaborators:

- Tanjima Tasnim
- Agnese Porro
- Alex Vigna Lobbia
- Andrea Boscolo Meneguolo

The analytical work and explanatory note were produced collaboratively.

## Repository contents

```text
.
├── .gitignore
├── README.md
├── code_takehome.do
├── explanatory_note.pdf
└── data/
    └── README.md
```

- [`code_takehome.do`](code_takehome.do) is a portable reconstruction of the code printed in `code_takehome.pdf`. It implements Problems I–V and writes generated files below `output/`.
- [`explanatory_note.pdf`](explanatory_note.pdf) is the original explanatory note, included unchanged.
- [`data/README.md`](data/README.md) documents the required inputs and their expected locations.

## Assignment objectives

The assignment links firm heterogeneity and trade to European integration, then studies how exposure to Chinese import competition varies across European regions and relates to political attitudes.

Part I uses a firm panel for France and Italy. It asks for descriptive comparisons in NACE 22 (publishing and printing) and NACE 36 (furniture), production-function and TFP estimation, analysis of productivity distributions and internationalisation premia, and firm-level markup measures. Part II asks for a shift-share measure of regional Chinese import exposure, an instrument based on US imports from China, regional maps and regressions, and links between trade exposure, French ESS Round 8 responses, and Comparative Manifesto Project party positions.

## Empirical methodology and analysis

### Part I — recoverable from the included script

1. Descriptive comparisons for French and Italian firms in 2007.
2. Cobb–Douglas value-added production functions estimated by OLS, Wooldridge (`prodest`), and Levinsohn–Petrin (`levpet`), with country and year controls where specified in the source.
3. A theoretical comparison of revenue- and value-added production functions.
4. Sector-specific 1st/99th-percentile TFP cleaning, kernel densities, skewness summaries, Pareto-tail regressions, and export/FDI productivity-premium regressions.
5. Price-cost-margin and De Loecker–Warzynski markup measures, exporter regressions, size controls, and a TFP-on-markup regression.

### Part II — reported results, unavailable source commands

The explanatory note constructs NUTS-2 import-exposure measures from pre-period employment shares and sectoral import growth; uses the analogous US import shock as an instrument; maps the shock and baseline manufacturing shares; and studies regional outcomes. It then merges French regional exposure with ESS Round 8 respondents, reports weighted OLS and IV specifications, first-stage diagnostics, and an Anderson–Rubin test, and relates exposure to a CMP-based corporatism score.

No matching Part II source commands were present in `code_takehome.pdf`. A separate `Graziosi project code.do` found in the working folder was not used: it is a 2024/2025 project with different authors, samples, specifications, and outcomes. Substituting it would misrepresent the submitted analysis.

## Main findings

The following figures are reported in the explanatory note; they were not recomputed during repository preparation:

- For sector 22, the labour elasticities are 0.415 (OLS), 0.501 (Wooldridge), and 0.362 (LP); for sector 36 they are 0.417, 0.363, and 0.320. The report interprets the estimator differences in light of simultaneity and input-choice bias.
- Mean WRDG TFP in French sector 22 rises from 110.72 in 2001 to 142.79 in 2007, while the corresponding Italian mean changes from 117.52 to 118.96. Estimated Pareto slopes also change, indicating that shifts are not uniform across the distribution.
- The reported all-exporter and pure-exporter log-productivity premia are 0.0903 and 0.0865. The FDI comparisons are larger, ranging from 0.146 to 0.226 depending on the comparison group.
- Mean markups are 1.68 using the PCM measure and 1.54 using DLW. The exporter coefficient is 0.214 without firm size and 0.188 with size; the reported TFP-on-markup coefficient is 0.1907.
- The regional maps show that high baseline manufacturing shares broadly align with greater China-shock exposure, while sectoral composition also matters.
- For the French ESS sample, the China-shock coefficient for `sbeqsoc` is −0.796 in OLS (`p` = 0.039) and −0.781 in IV (`p` = 0.030). The corporatism-score estimates are 0.396 in OLS and 0.404 in IV. The report treats these as evidence consistent with compensation and embedded-liberalism mechanisms, while cautioning that inference relies on a small number of regional clusters.

## Data availability

No datasets are tracked in this public-ready repository. The working folder contains course-provided, ESS/CMP-related, and geographic inputs whose redistribution permissions could not be established. It also contains generated intermediate datasets that should be recreated rather than versioned.

To run Part I, obtain the authorised course copy of `EEI_TH_P1_2026.dta` and place it at:

```text
data/EEI_TH_P1_2026.dta
```

See [`data/README.md`](data/README.md) for the additional inputs associated with the Part II results. Do not publish those files unless their licences and course redistribution terms expressly permit it.

## Software requirements

- Stata with support for factor variables and `table ... statistic()`
- User-written commands:
  - `outreg2`
  - `esttab` (from `estout`)
  - `prodest`
  - `levpet` and its dependencies
  - `grc1leg`

Install the packages from trusted Stata sources before running the script. Typical discovery/installation commands are:

```stata
ssc install outreg2
ssc install estout
ssc install grc1leg
search prodest
search levpet
```

Review the search results and install `prodest`, `levpet`, and the dependencies identified by Stata. The script checks availability and stops with an informative message if a command is missing; it does not install software automatically.

## Running the analysis

1. Clone or download this repository.
2. Put the authorised `EEI_TH_P1_2026.dta` file in `data/`.
3. Start Stata and set the working directory to the repository root.
4. Run:

   ```stata
   do code_takehome.do
   ```

The script creates:

```text
output/
├── figures/
├── intermediate/
├── logs/
└── tables/
```

All paths are relative to the repository root. The script uses fixed random seeds for the bootstrap-based Levinsohn–Petrin estimations where the source listing specified them.

Stata was not installed or discoverable during repository preparation, so the script was **not executed** and the numerical results were not independently reproduced. Validation was static: every PDF page was rendered and inspected, commands were compared section by section, multiline syntax and macros were checked, relative input/output references were audited, and the source datasets were inspected without modifying them. Execution-dependent behavior of the user-written estimators remains to be verified in a licensed Stata environment.

## Reconstruction notes

The Stata file was reconstructed from the 28-page `code_takehome.pdf` source listing and checked section by section against the rendered PDF. The following portability-only changes were made:

- removed machine- and username-specific working directories;
- changed input and output references to repository-relative paths;
- added output-directory creation and dependency checks;
- retained the original estimator choices, samples, seeds, comments, and model specifications;
- corrected the collaborator acknowledgement to use Andrea Boscolo Meneguolo’s full name;
- documented that the available listing stops after Problem V.

The source PDF contained a duplicated FDI-premium regression/export block in Problem IV(d). The reconstruction keeps one copy of the identical block; this removes duplicate output without changing the estimate or interpretation.

## Publication decisions

Included:

- the unchanged collaborative explanatory note;
- the reconstructed, portable Part I Stata script;
- documentation needed to reproduce the recoverable analysis.

Excluded:

- assignment instructions and other instructor/course materials;
- the original code-listing PDF, which duplicates the reconstructed script and exposes personal machine paths;
- all datasets, shapefiles, ESS/CMP inputs, and generated intermediate data because redistribution rights were not established;
- generated tables, graphs, and Stata graph files already represented in the explanatory note or reproducible from authorised inputs;
- the unrelated prior-year `Graziosi project code.do`.

## Rights

No open-source or data licence is asserted. The repository is prepared for review and reproducibility; reuse of the report, code, or data remains subject to the rights of the collaborators, course staff, and original data providers.
