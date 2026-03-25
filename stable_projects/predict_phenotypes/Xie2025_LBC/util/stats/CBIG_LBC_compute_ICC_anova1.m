function ICC = CBIG_LBC_compute_ICC_anova1(Y,subjectID,k)

% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
%
% Y: measurements: arranged as 1 column   e.g.,[FCY0_1;FCY0_2], FC value
% should first fisher r2z transformed
% subjecID: subjectID arranged as 1 column,and repeated k times e.g.,[FCY0_1_subID;FCY0_2_subID]
% k: Number of repeated measures per subject
            
% Perform one-way ANOVA
[~, table, ~] = anova1(Y, subjectID, 'off'); % 'off' suppresses the plot

% Extract Mean Squares
MSB = table{2, 4}; % Mean Square Between
MSW = table{3, 4}; % Mean Square Within

% Calculate ICC
ICC = (MSB - MSW) / (MSB + (k - 1) * MSW);
end

