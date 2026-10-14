# Data inputs

The analysis data are not redistributed in this public-ready repository. Place authorised copies of every required external input directly in this directory, using the exact filenames below.

## Required external inputs

| Required path | Format | Problems | Purpose | Located during audit? | Source/access notes |
|---|---|---:|---|---|---|
| `data/EEI_TH_P1_2026.dta` | Stata | I–V | France/Italy firm panel used for production functions, TFP, export/FDI premia, and markups | Yes | Course-provided file; redistribution permission was not established |
| `data/Employment_Shares_Take_Home.dta` | Stata | VI(a), VI(c) | Pre-sample regional-industry employment weights and 1988 manufacturing shares | Yes | Course-provided file; redistribution permission was not established |
| `data/Imports_China_Take_Home.dta` | Stata | VI(a) | Chinese import changes used in the regional shift-share shock | Yes | Course-provided file; redistribution permission was not established |
| `data/Imports_US_China_Take_Home.dta` | Stata | VI(a), VII(c), VII(f) | US imports from China used to construct the instrument | Yes | Course-provided file; redistribution permission was not established |
| `data/ESS8e02_3.dta` | Stata | VII(a)–VII(c) | European Social Survey Round 8 respondents and survey weights for France | **No** | Obtain through authorised ESS access; the repository does not supply it |
| `data/MPDataset_MPDS2025a.dta` | Stata | VII(e)–VII(f) | Comparative Manifesto Project party identifiers and `per405` | **No** | Obtain through authorised CMP access; the repository does not supply it |
| `data/NUTS_RG_20M_2013_3035.shp` | ESRI Shapefile geometry | VI(c) | 2013 NUTS boundaries in EPSG:3035 for the maps | Yes | Keep with every companion file listed below |
| `data/NUTS_RG_20M_2013_3035.shx` | Shapefile index | VI(c) | Geometry index | Yes | Required companion |
| `data/NUTS_RG_20M_2013_3035.dbf` | dBASE table | VI(c) | NUTS attributes such as region and country codes | Yes | Required companion |
| `data/NUTS_RG_20M_2013_3035.prj` | Projection definition | VI(c) | EPSG:3035 coordinate reference information | Yes | Required companion |
| `data/NUTS_RG_20M_2013_3035.cpg` | Encoding declaration | VI(c) | Attribute-text encoding | Yes | Required companion |

The script checks these files before the corresponding section runs and exits with an informative message when an input is missing.

## Inspected structures

The locally available Stata files had the following structures:

- `EEI_TH_P1_2026.dta`: 4,285 observations; `mark year country K L sales M W exporter FDI nace exp_intensity VA real_K real_M real_sales real_VA`.
- `Employment_Shares_Take_Home.dta`: 16,800 observations; `year country nuts2_name nuts2 nace empl tot_empl_nuts2 tot_empl_country_nace`.
- `Imports_China_Take_Home.dta`: 840 observations; `country year nace real_imports_china`.
- `Imports_US_China_Take_Home.dta`: 252 observations; `nace year real_USimports_china`.

The definitive script expects these fields from the unavailable external inputs:

- ESS: `cntry pspwght gndr agea edlvdfr region prtvtcfr sbeqsoc`.
- CMP: `countryname date party partyname partyabbrev per405`.

The geographic conversion expects NUTS identifiers and level/country attributes. The source bundle generated fields including `NUTS_ID`, `LEVL_CODE`, `CNTR_CODE`, `NAME_LATN`, and `NUTS_NAME`.

## Instruction/code discrepancy: dataset C

The assignment instructions identify `EEI_TH_P6_2026.dta` as dataset C and ask for datasets A–C to be merged in Problem VI(a). The file exists in the original assignment folder and contains 12,375 observations with:

```text
nuts_code nace2_2_group year tfp mean_uwage share_tert_educ
ind cou lnpop control_gdp
```

The definitive script explicitly says “dataset C not used” and never reads this file. It is therefore not a runtime dependency of the repository code, but its omission is a documented difference from the literal assignment instructions. No merge or analysis using dataset C has been invented during repository preparation.

## Generated files

Most intermediate datasets are Stata `tempfile` objects and disappear when the session ends. The reproducible shapefile conversions and merged map databases are written below:

```text
outputs/intermediate/
├── nuts2_db.dta
├── nuts2_coord.dta
├── nuts2_china_shock_db.dta
└── nuts2_manuf_share_db.dta
```

Final tables, figures, maps, and logs are written to the other `outputs/` subdirectories. None of these generated files should be placed in `data/`.

## Redistribution

Do not commit or publish any input until its course, ESS, CMP, Eurostat/GISCO, and other applicable access and redistribution terms have been checked. The repository’s `.gitignore` excludes data and generated outputs by default.
