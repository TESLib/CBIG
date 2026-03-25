#Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

# Load required libraries (assumes already installed)
suppressMessages({
  library(longCombat)  # https://github.com/jcbeer/longCombat
  library(invgamma)
  library(lme4)
})

CBIG_LBC_longCombat_motion <- function(input_csv_path,
                                       output_csv_path,
                                       idvar       = 'src_subject_id',
                                       timevar     = 'interview_age',
                                       batchvar    = 'SiteID',
                                       ranef       = '(1|src_subject_id)',
                                       formula_str = 'crossAge + longAge + sex',
                                       meanFD_col  = 9,
                                       stdFD_col   = 27) {
  
  # ----- Read input data -----
  Data <- read.csv(file = input_csv_path)
  
  # Safety check: column indices
  ncol_data <- ncol(Data)
  if (meanFD_col > ncol_data | stdFD_col > ncol_data) {
    stop("meanFD_col or stdFD_col index exceeds number of columns in Data.")
  }
  
  # Get the actual feature names for meanFD / stdFD
  feature_names <- c(colnames(Data)[meanFD_col],
                     colnames(Data)[stdFD_col])
  message("Features to be ComBat-harmonized: ",
          paste(feature_names, collapse = ", "))
  
  # ----- Convert relevant variables to factors -----
  Data[[batchvar]] <- factor(Data[[batchvar]])
  Data[[idvar]]    <- factor(Data[[idvar]])
  Data$sex         <- factor(Data$sex)
  Data$eventname   <- factor(Data$eventname)
  
  message("Checking factor status:")
  print(sapply(Data[, c(batchvar, idvar, 'sex', 'eventname')], is.factor))
  
  # ----- Run longCombat on meanFD & stdFD -----
  Data_combat <- longCombat(idvar   = idvar,
                            timevar = timevar,s
                            batchvar = batchvar,
                            features = feature_names,
                            formula  = formula_str,
                            ranef    = ranef,
                            data     = Data)
  
  # ----- Write output -----
  write.csv(Data_combat$data_combat, output_csv_path, row.names = FALSE)
  message("Motion longCombat complete. Output saved to: ", output_csv_path)
}
