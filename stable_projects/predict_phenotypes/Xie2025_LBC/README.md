# Convergent and Divergent Brain-Cognition Development in Early Adolescence

## Reference
Xie Y, et al. Convergent and Divergent Brain-Cognition Development in Early Adolescence. Nature Communications, 2026.

---

## Background
A major goal in cognitive neuroscience is to understand how individual differences in brain network development relate to variability in cognitive development. This is particularly salient during the transition from childhood to adolescence, a period marked by a shift from concrete to more abstract and logical thinking, which supports the growing ability to manage complex tasks and navigate increasingly demanding environments. Here, we leverage longitudinal resting-state fMRI and cognitive data from 2,949 children (ages 8.9 to 13.5) in the Adolescent Brain Cognitive Development (ABCD) Study at baseline and Year 2 to examine how stable and changing features of brain network organization predict cognitive development during this critical period.

## Code Release

### Download stand-alone repository
Since the whole Github repository is too big, we provide a stand-alone version of only this project and its dependencies. To download this stand-alone repository, visit this link:
https://github.com/ThomasYeoLab/Standalone_Xie2025_LBC

### Download whole repository
If you wish to use the codes for other stable projects from our lab as well, you will need to download the whole repository.

To download the version of the code that was last tested, you can either

visit this link: https://github.com/ThomasYeoLab/CBIG/releases/tag/v0.37.0-Xie2025_LBC

or run the following command, if you have Git installed:

```bash
git checkout -b Xie2025_LBC v0.37.0-Xie2025_LBC
```

---

## Usage

All replication scripts are located under `replication/`. Before running any script, set up the environment by sourcing the config file:

```bash
source replication/config/CBIG_LBC_tested_config.sh
```

The project is organized into 5 main analysis steps:

### Step 1 — Cognitive Stability and Change (`step1_cog_change/`)
Analyses of cognitive stability, longitudinal cognitive change, and individual differences in longitudinal cognitive change.

```bash
bash replication/CBIG_LBC_run_step1_cog_stabilty_change.sh
```

### Step 2 — FC Stability and Change (`step2_FC_change/`)
Analyses of FC stability, group-level longitudinal FC change, individual-level FC change, and individual differences in longitudinal FC change.

```bash
bash replication/CBIG_LBC_run_step2_FC_stabilty_change.sh
```

### Step 3 — KRR Prediction (`step3_KRR_predict/`)
Kernel ridge regression (KRR) prediction of cognition from FC. All analyses are controlled via a single script with a `mode` argument:

```bash
bash replication/CBIG_LBC_run_step3_KRR.sh <mode>
```

| Mode | Description | Conditions |
|---|---|---|
| `main` | Standard prediction | FCY0→CogY0, FCY2→CogY2, FCY2→CogY0, FCDelta→CogY2, FCY0→CogY2, FCY0(4min)→CogY2, FCDelta→CogDelta, FCY0→CogDelta |
| `sex` | Sex-stratified (male/female separately) | Same as main except FCY2→CogY0 |
| `generalize` | Generalization (replication sample) | Same as main except FCY2→CogY0 |
| `transfer` | Model transfer (Y0 model applied to Y2) | — |
| `all` | Run all 4 analyses above | — |

### Step 4 — FC Change Reliability (`step4_FC_change_reliability/`)
Analyses of FC reliability across scan durations, including ICC computation and reliability model fitting. Run the 3 steps sequentially:

```bash
bash replication/CBIG_LBC_run_step4_reliability.sh 1   # compute FC per subject
# wait for cluster jobs to finish
bash replication/CBIG_LBC_run_step4_reliability.sh 2   # combine FC across runs
# wait for cluster jobs to finish
bash replication/CBIG_LBC_run_step4_reliability.sh 3   # extract FC, compute ICC, fit model, estimate T
```

### Step 5 — Consistent/Inconsistent Predictive Network Features (`step5_consist_inconsist_PNF/`)
Computation of predictive network features (PNF) from PNF matrices, extraction of parcel-level and network-block-level feature maps, and comparison of consistent and inconsistent PNF.

### Utility functions (`util/`)
Contains shared utility scripts called by the main analyses, organized into subfolders:
- `util/stats/`: statistical functions including network-level stats and longitudinal ComBat
- `util/plot/`: plotting utilities and color schemes
- `util/xDF/`: autocorrelation-corrected FC tools
- `util/Yan_400label/`: Yan 2023 400-parcel atlas labels

---

## Updates
- Release v0.37.0(25/03/2026): Initial release of Xie2025_LBC
---

## Bugs and Questions
Please contact Yapei Xie at yap.xie@gmail.com and Thomas Yeo at yeoyeo02@gmail.com
