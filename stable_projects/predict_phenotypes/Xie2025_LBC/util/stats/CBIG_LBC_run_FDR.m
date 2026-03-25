function [FDR_sig_idx_sets, pID] = CBIG_LBC_run_FDR(q_thres, varargin)
% CBIG_LBC_run_FDR
%
% Apply FDR correction on p-values pooled across N different sets.
% 
%
% All input vectors are concatenated and corrected together using FDR.
% The resulting p-value cutoff (pID) is then used to identify significant
% p-values in each original set.
%
% Usage:
%   [FDR_sig_idx_sets, pID] = CBIG_LBC_run_FDR(0.05, p1, p2, ..., pN)
%
% Inputs:
%   - q_thres: scalar, desired FDR threshold (e.g., 0.05)
%   - varargin: N input p-value vectors
%
% Outputs:
%   - FDR_sig_idx_sets: 1 x N cell array.
%       Each cell contains the indices of significant p-values in the
%       corresponding input vector after pooled FDR correction.
%   - pID: scalar. The FDR-corrected p-value threshold.
%
% Example:
%   [idx_sets, pID] = CBIG_LBC_run_FDR(0.05, p_stability, p_cohen_d);
%
% Note: The helper function `gretna_FDR` below was originally written by
%   Jinhui Wang, and is included here for convenience. 
%   Source: gretna toolbox (https://www.nitrc.org/projects/gretna).
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

    if nargin < 2
        error('Usage: CBIG_LBC_run_FDR(p_thres, p1, p2, ..., pN)');
    end

    % Concatenate all p-values
    all_p = [];
    lens = zeros(1, length(varargin));  % length of each p-value vector
    for i = 1:length(varargin)
        pi = varargin{i};
        if ~isvector(pi)
            error('Input %d is not a vector.', i);
        end
        pi = pi(:);  % ensure column vector
        lens(i) = length(pi);
        all_p = [all_p; pi];
    end

    % Run pooled FDR correction
    [pID, ~] = gretna_FDR(all_p, q_thres);

   % If no valid FDR threshold is found, return empty
if isempty(pID)
    FDR_sig_idx_sets = cell(1, length(varargin));
    for i = 1:length(varargin)
        FDR_sig_idx_sets{i} = [];
    end
    return;
end

% Extract significant indices for each original set
FDR_sig_idx_sets = cell(1, length(varargin));
curr_idx = 0;
for i = 1:length(varargin)
    range = curr_idx + (1:lens(i));
    sig_idx = find(all_p(range) <= pID);
    FDR_sig_idx_sets{i} = sig_idx;
    curr_idx = curr_idx + lens(i);
end


function [pID,pN] = gretna_FDR(p,q)
%==========================================================================
% This function is used to correct multiple comparissons based on False
% Discovery Rate (FDR) procedure.
%
%
% Syntax: function [pID,pN] = gretna_FDR(p,q)
% 
% Inputs:
%        p:
%           Vector of p-values.
%        q:
%           False Discovery Rate level.
%
% Outputs:
%        pID:
%           P-value threshold based on independence or positive dependence
%           at FDR level of q.
%        pN:
%           Nonparametric p-value at FDR level of q.
%
% Jinhui WANG, NKLCNL, BNU, BeiJing, 2011/10/23, Jinhui.Wang.1982@gmail.com
%==========================================================================

p = sort(p(:));
V = length(p);
I = (1:V)';

cVID = 1;
cVN = sum(1./(1:V));

pID = p(find(p<=I/V*q/cVID, 1, 'last' ));
pN  = p(find(p<=I/V*q/cVN,  1, 'last' ));

end
end
