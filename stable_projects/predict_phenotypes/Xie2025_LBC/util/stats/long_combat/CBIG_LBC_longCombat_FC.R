# Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

# Helper function to install and load packages
personal_lib <- Sys.getenv("R_LIBS_USER", unset = path.expand("~/R/library"))
dir.create(personal_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(personal_lib, .libPaths()))

install_if_missing <- function(pkg, github_repo = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Installing package: ", pkg)
    if (!is.null(github_repo)) {
      if (!requireNamespace("remotes", quietly = TRUE)) {
        install.packages("remotes", lib = personal_lib, repos = "https://cloud.r-project.org")
      }
      remotes::install_github(github_repo, lib = personal_lib)
    } else {
      install.packages(pkg, lib = personal_lib, repos = "https://cloud.r-project.org")
    }
  }
}

# Install packages if not already installed
install_if_missing("longCombat", github_repo = "jcbeer/longCombat")
install_if_missing("invgamma")
install_if_missing("lme4")

# Load required libraries
suppressMessages({
  library(longCombat)
  library(invgamma)
  library(lme4)
})

CBIG_LBC_longCombat_FC <- function(input_csv_path,
                                     output_csv_path,
                                     idvar = 'src_subject_id',
                                     timevar = 'interview_age',
                                     batchvar = 'SiteID',
                                     ranef = '(1|src_subject_id)',
                                     formula_str = 'crossAge + longAge + sex + MeanFD',
                                     feature_start_col = 15,
                                     feature_end_col = 87585) {
  
  # Read input data
  Data <- read.csv(file = input_csv_path)
  
  # Convert relevant variables to factors
  Data[[batchvar]] <- factor(Data[[batchvar]])
  Data[[idvar]] <- factor(Data[[idvar]])
  Data$sex <- factor(Data$sex)
  Data$eventname <- factor(Data$eventname)
  
  # Check factor status (optional)
  message("Checking factor status:")
  print(sapply(Data[, c(batchvar, idvar, 'sex', 'eventname')], is.factor))
  
  # Select features
  RespondNames <- colnames(Data)[feature_start_col:feature_end_col]
  
  # Run longCombat
  Data_combat <- longCombat(idvar = idvar,
                            timevar = timevar,
                            batchvar = batchvar,
                            features = RespondNames,
                            formula = formula_str,
                            ranef = ranef,
                            data = Data)
  
  # Write output
  write.csv(Data_combat$data_combat, output_csv_path, row.names = FALSE)
  
  message("Combat harmonization complete. Output saved to: ", output_csv_path)
}
