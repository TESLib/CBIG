# run_longComBat_cog.R

# get env variable
LBC_rep_dir <- Sys.getenv("LBC_rep_dir")

if (LBC_rep_dir == "") {
  stop("LBC_rep_dir environment variable not found. Did you source config.sh?")
}

# Get repo root from environment variable defined in config.sh
CBIG_CODE_DIR <- Sys.getenv("CBIG_CODE_DIR")

if (CBIG_CODE_DIR == "") {
  stop("CBIG_CODE_DIR not found. Did you source CBIG_LBC_tested_config.sh?")
}

repo_root <- file.path(
  CBIG_CODE_DIR,
  "stable_projects",
  "predict_phenotypes",
  "Xie2025_LBC"
)

# File paths
source(file.path(repo_root, "util", "stats", "long_combat", "CBIG_LBC_longCombat_cognition.R"))
input_csv_path <- file.path(LBC_rep_dir, "Data", "DemoCog_Y0Y2.csv")
output_csv_path <- file.path(LBC_rep_dir, "Data", "cog_Y0Y2_combat.csv")

# Run function
CBIG_LBC_longCombat_cognition(input_csv_path, output_csv_path)

