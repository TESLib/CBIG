## Example of running KRR
This example runs the kernel ridge regression code for simulated data.

### Input
Data for this example can be found in the `example_data/sim_data` folder. 

A description of the data for the subjects are as follows.
1. `y.mat`: A mat file of the variables to be predicted.
2. `RSFC.mat`: A mat file of the features to be used for prediction.
3. `covariates.mat`: A mat file of covariates to control for.
4. `no_relative_2_fold_sub_list.mat`: a mat file of the cross validation structure.

### Scripts
1. `CBIG_LBC_KRR_example_wrapper.m`: Runs the KRR prediction.
2. `CBIG_LBC_KRR_check_example_results.m`: Checks whether the output of the example are the same as the reference results.
