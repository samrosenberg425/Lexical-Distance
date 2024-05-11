function LexicalDistanceAnalysis
% Add functions directory to the MATLAB search path
current_dir = pwd;
subfolder = 'Functions';
folderToAdd = fullfile(current_dir, subfolder);
addpath(folderToAdd);

% Create UI for setting up files or running analysis
fig = uifigure('Name', 'Choose Action', 'Position', [500, 400, 300, 150]);
setupFilesButton = uibutton(fig, 'Text', 'Set up files', 'Position', [25, 100, 100, 22], 'ButtonPushedFcn', @(~,~) setupFiles(fig));
runAnalysisButton = uibutton(fig, 'Text', 'Run analysis', 'Position', [175, 100, 100, 22], 'ButtonPushedFcn', @(~,~) runAnalysis(fig));
helpButton = uibutton(fig, 'Text', 'Help', 'Position', [100, 50, 100, 22], 'ButtonPushedFcn', @(~,~) showHelpDialog(fig));

% Callback function for setting up files
function setupFiles(fig)
    % Close the current figure
    close(fig);
    % Call the file setup function
    setup_gui();  
end

% Callback function for running the analysis
function runAnalysis(fig)
    close(fig);  
    MatrixSelector;
end

% Callback function for running the analysis
function showHelpDialog(fig)
    intro='This is a tool that is designed to create distance matrices of subleixcal/lexical features.';
    mat_output='   -Feature, Experience, Feature*Experience, and Control matrices(saved as .mat files in the specified output folder';
    run_an_output = '   -.mat file with residuals of selected matrices';
    run_an_output2= '   -Excel file with a summary of correlations between residuals(and associated p values)';
    helpContent={intro; '';'Usage'; 'Set Up Funtion'; '  Input';''; '   -List of Words'; ''; ...
        '  GUI Selection'; '   -Analysis/folder name'; ''; '  Output'; mat_output; '   -.txt file of words'; '';...
        'Run Analysis';'';'  Input'; '   -Folder with .mat files of matrices(from set up function)'; ''; ...
        '  GUI Selection'; '   -Matrices to partial/save residuals of'; '   -Analysis Name'; '   -Correlation Type(Spearman or Kenall';...
        '  Output'; run_an_output; run_an_output2;''};
    helpwindpw=msgbox(helpContent, 'Help');
    
end

end