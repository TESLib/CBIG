function CBIG_LBC_prepare_FC_LongCombatTable(LBC_rep_dir)
% CBIG_LBC_prepare_FC_LongCombatTable(LBC_rep_dir)
%
% Prepare FC_Y0Y2.csv for longCombat harmonization by combining demographic
% meta-columns (cols 1-14) from DemoCog tables with FC edges from
% FC_final_Y0 and FC_final_Y2.
%
% Input:
%     - LBC_rep_dir: (string)
%           Path to the replication folder. Must contain:
%             * Data/FC_final_Y0.mat (variable: FC_final_Y0)
%             * Data/FC_final_Y2.mat (variable: FC_final_Y2)
%             * Data/DemoCog_Y0.csv
%             * Data/DemoCog_Y2.csv
%
% Output:
%     - FC_Y0Y2.csv saved to [LBC_rep_dir]/Data/, a stacked longitudinal
%       table (Y0 rows followed by Y2 rows) for longCombat harmonization.
%
% Example:
%     CBIG_LBC_prepare_FC_LongCombatTable('/path/to/rep')
%
% Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

if nargin < 1
    LBC_rep_dir = getenv('LBC_rep_dir');
end
if isempty(LBC_rep_dir)
    error('LBC_rep_dir not set. Did you source config.sh?');
end

% -- Load FC matrices -------------------------------------------------------
load(fullfile(LBC_rep_dir, 'Data', 'FC_final_Y0.mat'), 'FC_final_Y0');
load(fullfile(LBC_rep_dir, 'Data', 'FC_final_Y2.mat'), 'FC_final_Y2');

% -- Load demographic tables ------------------------------------------------
DemoCog_Y0 = readtable(fullfile(LBC_rep_dir, 'Data', 'DemoCog_Y0.csv'));
DemoCog_Y2 = readtable(fullfile(LBC_rep_dir, 'Data', 'DemoCog_Y2.csv'));

% -- Stack meta-columns (cols 1-14) ----------------------------------------
DemoTable = [DemoCog_Y0(:, 1:14); DemoCog_Y2(:, 1:14)];

% -- Stack FC matrices (subjects x edges) and convert to table -------------
% FC_final is (n_edges x n_subjects), transpose to (n_subjects x n_edges)
FC_table = array2table([FC_final_Y0'; FC_final_Y2']);

% -- Combine and save -------------------------------------------------------
LongCombatTable = [DemoTable, FC_table];

fprintf('LongCombatTable size: %d rows x %d columns\n', ...
    height(LongCombatTable), width(LongCombatTable));
fprintf('First FC edge column name: %s\n', ...
    LongCombatTable.Properties.VariableNames{15});

output_path = fullfile(LBC_rep_dir, 'Data', 'FC_Y0Y2.csv');
writetable(LongCombatTable, output_path);
fprintf('Saved to: %s\n', output_path);

end
