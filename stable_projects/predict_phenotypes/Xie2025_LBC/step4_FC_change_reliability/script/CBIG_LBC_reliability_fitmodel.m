function CBIG_LBC_reliability_fitmodel(icc_matfile, output_matfile)
% CBIG_LBC_reliability_fitmodel(icc_matfile, output_matfile)
%
% Estimate reliability growth model parameters (sigma^2, tau^2) for Y0 and Y2
% across all FC edges using ICC values at 5 scan durations (2–10 min).
%
% Input:
%     - icc_matfile: (string)
%           Path to .mat file containing ICC_Y0 and ICC_Y2 structs with fields
%           '2min', '4min', '6min', '8min', '10min' (each a vector of n_edges).
%
%     - output_matfile: (string)
%           Path to save results (.mat).
%
% Output:
%     - A .mat file saved to output_matfile containing 'Y0_Para', 'Y2_Para'
%       (each 3 x n_edges: sigma^2, tau^2, R^2) and 'Y0_Predict', 'Y2_Predict'
%       (each 6 x n_edges: predicted ICC at 2, 4, 6, 8, 10, 20 min).
%
% Example:
%     CBIG_LBC_reliability_fitmodel('ICC_results.mat', 'Reliability_FitModel_Results.mat')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

% Load ICC structs
load(icc_matfile, 'ICC_Y0', 'ICC_Y2');

nEdges = length(ICC_Y0.('2min'));

% Output containers
Y0_Para = zeros(3, nEdges);    % sigma^2, tau^2, R^2
Y2_Para = zeros(3, nEdges);
Y0_Predict = zeros(6, nEdges); % R_pred at 2,4,6,8,10,20min
Y2_Predict = zeros(6, nEdges);

% Time points
T = [2; 4; 6; 8; 10];

% Loop over edges
for counter = 1:nEdges
    if mod(counter, 1000) == 0
        fprintf('Processing edge %d / %d\n', counter, nEdges);
    end

    % Extract reliability values at 5 durations
    Reliability_Y0 = [ICC_Y0.('2min')(counter); ICC_Y0.('4min')(counter); ...
        ICC_Y0.('6min')(counter); ICC_Y0.('8min')(counter); ICC_Y0.('10min')(counter)];
    Reliability_Y2 = [ICC_Y2.('2min')(counter); ICC_Y2.('4min')(counter); ...
        ICC_Y2.('6min')(counter); ICC_Y2.('8min')(counter); ICC_Y2.('10min')(counter)];

    %% Fit Y0
    [sigma2, tau2, ~] = estimateSigmaTauAuto(Reliability_Y0, T);
    R_pred = sigma2 ./ (sigma2 + (tau2 ./ T));
    SSres = sum((Reliability_Y0 - R_pred).^2);
    SStot = sum((Reliability_Y0 - mean(Reliability_Y0)).^2);
    R2 = 1 - (SSres / SStot);
    Y0_Para(:, counter) = [sigma2; tau2; R2];
    R_pred_20 = sigma2 / (sigma2 + (tau2 / 20));
    Y0_Predict(:, counter) = [R_pred; R_pred_20];

    %% Fit Y2
    [sigma2, tau2, ~] = estimateSigmaTauAuto(Reliability_Y2, T);
    R_pred = sigma2 ./ (sigma2 + (tau2 ./ T));
    SSres = sum((Reliability_Y2 - R_pred).^2);
    SStot = sum((Reliability_Y2 - mean(Reliability_Y2)).^2);
    R2 = 1 - (SSres / SStot);
    Y2_Para(:, counter) = [sigma2; tau2; R2];
    R_pred_20 = sigma2 / (sigma2 + (tau2 / 20));
    Y2_Predict(:, counter) = [R_pred; R_pred_20];
end

% Save results
save(output_matfile, 'Y0_Para', 'Y2_Para', 'Y0_Predict', 'Y2_Predict', '-v7.3');

end
