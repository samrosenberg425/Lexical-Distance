function setup_gui
    current_dir=pwd;
    subfolder='Functions';
    folderToAdd = fullfile(current_dir);
    % Add the folder to MATLAB's search path
    addpath(folderToAdd);
    
    % Create a figure window
    fig = uifigure('Name', 'Input Wordlist', 'Position', [500, 400, 300, 250]);

    % Add a label above the text box
    label = uilabel(fig, 'Text', 'Enter wordlist separated by commas', 'Position', [50, 150, 200, 22]);
    
    label2 = uilabel(fig, 'Text', 'OR', 'Position', [140, 165, 40, 20]);
    
    label3 = uilabel(fig, 'Text', 'Enter Output Folder Name', 'Position', [20, 220, 150, 22]);

    % Add a button to select a file
    fileButton = uibutton(fig, 'Text', 'Select .csv File with wordlist', 'Position', [50, 185, 200, 22], 'ButtonPushedFcn', @selectFile);

    % Add a text box for inputting text
    textBox = uitextarea(fig, 'Position', [50, 30, 200, 120]);
    
    textBox2 = uitextarea(fig, 'Position', [180, 220, 110, 22]);
    % Add a button to run the operation
    runButton = uibutton(fig, 'Text', 'Run', 'Position', [125, 5, 40, 20], 'ButtonPushedFcn', @(~, ~) runOperation(fig));

    % Callback function for file selection
    function selectFile(~, ~)
        % Prompt the user to select a CSV file
        [fileName, filePath] = uigetfile({'*.csv', 'CSV Files'}, 'Select .csv File');
        if fileName ~= 0
            % Read the content of the CSV file
            fileContent = readmatrix(fullfile(filePath, fileName), 'OutputType', 'string');
            % Convert the file content to a cell array of words
            wordlist = split(fileContent, ",");
            % Update the text box with the selected path
            textBox.Value = strjoin(wordlist, ", ");
        end
    end

    % Callback function for running the operation
    function runOperation(fig)
        % Check if a file or list is entered
        inputText = textBox.Value;
        if isempty(textBox2.Value)
            % If empty, assign a default name
            an_name = 'Output_Matrices';
        else
            % Otherwise, use the entered name
            an_name = char(textBox2.Value);
        end
        % Split the input text into individual words
        inputText=strrep(inputText, ' ', '');
        wordlist = split(inputText, ",");
        wordlist=sort(wordlist);
        close(fig);
        %disp('Wordlist:');
        %disp(wordlist);
        masterlist=table2cell(readtable('data/wordlist.txt'));
        is_in=ismember(wordlist, masterlist);
        if any(is_in==0)
            missing_words=string(wordlist(find(is_in==0)));
            uialert(fig, sprintf('The following words are not in the corpus: %s \nEnter a wordlist without them to run.', missing_words), 'Error: Words Not In Corpus')
            return
        end
        jpglove = readtable('data/4_19_glove_output.txt');
        data=readtable("data/PGToolkitMasterList_v2.xlsx");
        indPG_data = readtable('data/Individual_PG_values_v2.xlsx');
        freq=data(:, {'Word', 'Freq_SUBTLEXUS'});
        % Call functions for making matrices
        work_dir=pwd;
        [fDM, cDM] = make_fDM_cDM(wordlist, an_name, work_dir, data, jpglove);
        eDM = make_eDM(wordlist, an_name, work_dir, indPG_data, freq);
        feDM = make_feDM(wordlist, an_name, work_dir, data, fDM, cDM, eDM);
        directoryPath=fullfile(work_dir, sprintf('%s', an_name));
        if exist(directoryPath, 'dir') ~= 7
            % If the directory doesn't exist, create it
            mkdir(directoryPath);
        end
        fprintf('Saving Wordlist - Task 5/5')
        writecell(wordlist, fullfile(directoryPath, 'wordlist.txt'))
        fprintf('Finished making setup files \n')
        %close(fig);
        LexicalDistanceAnalysis();
    end 
end
