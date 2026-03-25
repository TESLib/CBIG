function Mean_Network = CBIG_ABCD_compute_average_major_network(PFM, withSubcortical)
% CBIG_ABCD_compute_average_major_network
% 
% Compute the average network-level values from a vectorized
% parcel-wise matrix (e.g., 419x419).
%
% This function uses the major version of the kong 17 network definitions 
% (e.g., 8 networks). The input vector is converted to a full 
% matrix, reordered according to the network assignments, and averaged 
% within each pair of networks.
%
% INPUTS:
%   - PFM: A 1D vector representing the lower triangle (excluding diagonal)
%          of a symmetric matrix (vectorized form, as from squareform).
%   - withSubcortical: A binary flag indicating whether to include subcortical regions.
%          * If 1, includes subcortex).
%          * If 0, includes only cortical networks.
%
% OUTPUTS:
%   - Mean_Network: A vectorized lower triangle (including diagonal) of the
%                   average network matrix.
%
% Dependencies:
%   - Requires 'Yan_NetworkIndex.mat' which contains 'Index' and 
%     'NetworkRange_major' variables.
%
% Example usage:
%   avg_net = CBIG_LBC_ABCD_compute_average_major_network(fc_vector, 1);
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

    % Load network index and ranges
repo_root = fullfile(getenv('CBIG_CODE_DIR'), 'stable_projects', 'predict_phenotypes', 'Xie2025_LBC');
load(fullfile(repo_root,'util','Yan_400label','NetworkIndex_YanKong17.mat'),'Index','NetworkRange_major')
   
    % Vector to matrix form and reorder
    PFM_mat = squareform(PFM);

    if withSubcortical == 1
        reordered_Index = Index;
        num_networks = 9;
    else
        reordered_Index = Index(1:400);  % Exclude subcortical nodes
        num_networks = 8;
    end

    PFM_mat_reorder = PFM_mat(reordered_Index, reordered_Index);
    Mean_Network_full = zeros(num_networks, num_networks);

    for i = 1:num_networks
        for j = 1:num_networks
            Mean_Network_full(i, j) = mean(mean( ...
                PFM_mat_reorder(NetworkRange_major{i}, NetworkRange_major{j})));
        end
    end

    % Extract lower triangle (including diagonal)
    ind = tril(true(num_networks));
    Mean_Network = Mean_Network_full(ind);
end
