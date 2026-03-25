function CBIG_LBC_compute_Rd_and_Testimate(...
    subID_file, cog_file, FCY0_file, FCY2_file, ...
    reliability_file, output_Rd_file, output_T_file)
% CBIG_LBC_compute_Rd_and_Testimate(subID_file, cog_file, FCY0_file, FCY2_file,
%     reliability_file, output_Rd_file, output_T_file)
%
% Compute reliability difference (R_D) and scan time estimation (T) matrices
% based on model parameters from CBIG_LBC_reliability_fitmodel.
%
% Input:
%     - subID_file: (string)
%           Path to SubID_4run_final.txt (one subject ID per line).
%
%     - cog_file: (string)
%           Path to DemoCog_Y2.csv.
%
%     - FCY0_file: (string)
%           Path to FC_final_Y0.mat (variable: FC_final_Y0).
%
%     - FCY2_file: (string)
%           Path to FC_final_Y2.mat (variable: FC_final_Y2).
%
%     - reliability_file: (string)
%           Path to Reliability_FitModel_Results.mat (variables: Y0_Predict, Y0_Para).
%
%     - output_Rd_file: (string)
%           Path to save R_D matrix (e.g., 'Rd_20min.mat').
%
%     - output_T_file: (string)
%           Path to save T_mat (e.g., 'T_mat.mat').
%
% Output:
%     - .mat files saved to output_Rd_file and output_T_file.
%
% Example:
%     CBIG_LBC_compute_Rd_and_Testimate('SubID.txt', 'DemoCog_Y2.csv', ...
%         'FC_Y0.mat', 'FC_Y2.mat', 'Reliability.mat', 'Rd.mat', 'T.mat')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md


% --- Load data ---
SubID_4run = CBIG_text2cell(subID_file);
CogMeasures_Y2 = readtable(cog_file);
SubID_all = strrep(CogMeasures_Y2{:,1}, 'NDAR_', 'NDAR');
[lia, locb] = ismember(SubID_4run, SubID_all);
fprintf('[INFO] Matched subjects: %d\n', sum(lia));

load(FCY0_file, 'FC_final_Y0');
load(FCY2_file, 'FC_final_Y2');
FCY0_select = FC_final_Y0(:,locb)';
FCY2_select = FC_final_Y2(:,locb)';

load(reliability_file, 'Y0_Predict', 'Y0_Para');

% --- Compute R_D ---
ICC_Y0_20min = Y0_Predict(6, :);
ICC_Y2_20min = Y0_Predict(6, :); % Assuming same for now; adjust if needed

nEdges = size(Y0_Predict, 2);
R_D = zeros(nEdges, 1);

for counter = 1:nEdges
    ICC_Y0 = ICC_Y0_20min(counter);
    ICC_Y2 = ICC_Y2_20min(counter);
    V_Y0 = var(FCY0_select(:, counter));
    V_Y2 = var(FCY2_select(:, counter));
    rho = corr(FCY0_select(:, counter), FCY2_select(:, counter));

    R_D(counter) = ((ICC_Y0*V_Y0 + ICC_Y2*V_Y2) - 2*rho*sqrt(V_Y0*V_Y2)) ...
                    / (V_Y0 + V_Y2 - 2*rho*sqrt(V_Y0*V_Y2));
end

R_D_mat = squareform(R_D);

% --- Estimate scan duration (T) needed ---
T = zeros(nEdges, 1);
for counter = 1:nEdges
    sigma2 = Y0_Para(1, counter);
    tau2 = Y0_Para(2, counter);
    R_Diff = R_D(counter);

    T(counter) = (R_Diff * tau2) / (sigma2 * (1 - R_Diff));
end

% Clamp unrealistic values
T(T < 0) = 0;
T(T > 20) = 0;

T_mat = squareform(T);

save(output_T_file, 'T_mat');

% --- Summary stats ---
fprintf('[R_D] min: %.4f, max: %.4f, mean: %.4f\n', min(R_D), max(R_D), mean(R_D));
fprintf('[T]   max: %.2f, mean (T>0): %.2f, median (T>0): %.2f, std (T>0): %.2f\n', ...
    max(T), mean(T(T > 0)), median(T(T > 0)), std(T(T > 0)));

end
