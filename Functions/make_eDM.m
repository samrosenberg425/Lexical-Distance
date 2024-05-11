function eDM=make_eDM(wordlist, analysis_name, w_dir, data, freq, mtype, within)
    fprintf('Making experience(eDM) distance matrices \n')


    % Check if mtype argument is provided, otherwise assign default value
    if nargin < 6 || isempty(mtype)
        mtype = 'min_tertile_threshold';
    end

    % Check if within argument is provided, otherwise assign default value
    if nargin < 7 || isempty(within)
        within = true;
    end
    %% Chose the value to use in your calculations
    [numOfWords, ~] = size(wordlist);

    if contains(mtype, 'tertile')
        low_thresh=1/3;
        high_thresh=2/3;
    elseif contains(mtype, 'quartile')
        low_thresh=1/4;
        high_thresh=3/4;    
    end


    %% Load data
    letterFreq = readtable("data/Letter Frequency.xlsx", 'ReadVariableNames', true);
    OR_data=readtable('data/Individual_OR_values_v2.xlsx');
    Ltr_data=readtable('data/Individual_Letter_Freq_v2.xlsx');

    data=join(data, OR_data, 'Keys', {'Word', 'IPA'});
    Ltr_data.("Word")=[];
    data=horzcat(data, Ltr_data);

    % zscore numeric columns
    % Identify numeric columns
    numericColumns = varfun(@isnumeric, data, 'OutputFormat', 'uniform');

    if ~within
    % Apply zscore only to numeric columns
        for i = 1:length(numericColumns)
            if numericColumns(i)
                mu = nanmean(data{:,i});
                lower_tertile(i)=quantile(data{:,i}, low_thresh);
                upper_tertile(i)=quantile(data{:,i}, high_thresh);
                max_tally(i)=max(data{:,i});
            else
                lower_tertile(i)=0;
                upper_tertile(i)=0;
            end
        end
    end

    %% Isolate wordlist data

    [numOfWords, ~] = size(wordlist);
    
    for s = 1:numOfWords
        val=find(strcmp(string(wordlist{s, 1}), string(data.Word)) == 1);
        if ~isempty(val)
            val=val(1);
            r(s) = val; 
        else
            numOfWords=numOfWords-1;
        end
         
    end
    
    wordlist = string(data.Word(r)); %wordlist and randWords are the same
    newdata=data(r,:);
    newfreq=freq(r,:);

    if within
        % Apply zscore only to numeric columns
        for i = 1:length(numericColumns)
            if numericColumns(i)
                mu = nanmean(data{:,i});
                lower_tertile(i)=quantile(newdata{:,i}, low_thresh);
                upper_tertile(i)=quantile(newdata{:,i}, high_thresh);
                max_tally(i)=max(newdata{:,i});
            else
                lower_tertile(i)=0;
                upper_tertile(i)=0;
            end
        end
    end

    %% Set up GP Table
    wp_tally = nchoosek(1:numOfWords, 2);
    GP_Mask = startsWith(newdata.Properties.VariableNames, 'GP') & cellfun('length', newdata.Properties.VariableNames) <= 4; % determines what columns in ntr_word_masterlist begin with lowercase "pg"
    GP_Table = newdata{:, GP_Mask}; % omits columns that do not begin with "pg"
    % Take longer word and comapre it to shorter word

    %% Preallocate arrays
    GP_Prob = zeros(numOfWords); % Grapheme frequency
    P_Freq = zeros(numOfWords); % Phoneme frequency
    GP_Freq = zeros(numOfWords);
    G_Freq = zeros(numOfWords);
    Ltr_Freq = zeros(numOfWords);
    OR_Freq=zeros(numOfWords);
    OR_Prob=zeros(numOfWords);


    %% Setting variables for calculation step
    [numLow, numMiddle, numUpper] = deal(zeros(1));
    [numLowGP, numMiddleGP, numUpperGP] = deal(zeros(1));
    [numLowP, numMiddleP, numUpperP] = deal(zeros(1));
    [numLowG, numMiddleG, numUpperG] = deal(zeros(1));
    [numLowOR, numMiddleOR, numUpperOR] = deal(zeros(1));
    [numLowORProb, numMiddleORProb, numUpperORProb] = deal(zeros(1));

    %% Running loop
    % For tertile line
    if contains(mtype, 'min')
        measures={'GP_Prob_Min', 'GP_Freq_Min', 'P_Freq_Min', 'Graph_Freq_Min', 'Min_OR_Freq', 'Min_OR_Prob', 'Min_Ltr_Freq'};
    elseif contains(mtype, 'mean')
        measures={'GP_Prob_Mean', 'GP_Freq_Mean', 'P_Freq_Mean', 'Graph_Freq_Mean', 'Mean_OR_Freq', 'Mean_OR_Prob', 'Mean_Ltr_Freq'};
    end
    % Each pair is for one measure(i and i+len(array)/2
    array_terms={'GP', 'GP', 'P', 'Graph', 'OR', 'OR', 'Ltr', 'Prob', 'Freq', 'Freq', 'Freq', 'Freq', 'Prob', 'Freq'};
    % To be used in loop
    match=length(array_terms)/2;
    calcvals=array2table(zeros(3,7), 'RowNames', {'Upper', 'Middle', 'Lower'}, 'VariableNames', {'GP_Prob', 'GP_Freq', 'P_Freq', 'G_Freq', 'OR_Freq', 'OR_Prob', 'Ltr_Freq'});
    results = struct('GP_Prob', GP_Prob, 'GP_Freq', GP_Freq,  'P_Freq', P_Freq, 'G_Freq', G_Freq, 'OR_Freq', OR_Freq, 'OR_Prob', OR_Prob, 'Ltr_Freq', Ltr_Freq);
    names=fieldnames(results);

    for t = 1:size(wp_tally, 1)
        fprintf("Number of runs: %d of %d (Making eDM - Task 3/5) \n", t, size(wp_tally, 1))
        % Load in word
        word1 = char(wordlist(wp_tally(t, 1), 1)); % grabs word 1 from wordlist
        word2 = char(wordlist(wp_tally(t, 2), 1)); % grabs word 2 from wordlist
        if length(word1)>=length(word2)
            longer_word=word1;
            shorter_word=word2;
        else
            longer_word=word2;
            shorter_word=word1;
        end

        % Get word indexes
        long_index = find(strcmp(longer_word, string(newdata.Word)) == 1); %finding where word1 is in the unique word list
        short_index = find(strcmp(shorter_word, string(newdata.Word)) == 1); %find word2 in unique word list

        % Get word lengths in GP
        long_Length=newdata.('Num_GP')(long_index);
        short_Length=newdata.('Num_GP')(short_index);

        % Get word lengths in OR
        long_OR_Length=newdata.('Num_OR')(long_index);
        short_OR_Length=newdata.('Num_OR')(short_index);

        % Get word lengths letter
        long_Ltr_Length=newdata.('Num_Ltr')(long_index);
        short_Ltr_Length=newdata.('Num_Ltr')(short_index);

        % Extract measures for word
        long_vals=newdata(long_index,:);
        short_vals=newdata(short_index,:);

        % Goes through each GP position on
        difflength=long_Length+short_Length;

        % Remove all features outside of length of word
        len=113;
        for i=long_Length+1:17
            colsToRemove = find(contains(long_vals.Properties.VariableNames(1:len), strcat([num2str(i)])) == 1);
            long_vals = removevars(long_vals, long_vals.Properties.VariableNames(colsToRemove));
            len=len-length(colsToRemove);
        end
        long_len=max(find(contains(long_vals.Properties.VariableNames, 'Graph')))+1;
        len=113;
        for i=short_Length+1:17
            colsToRemove = find(contains(short_vals.Properties.VariableNames(1:len), strcat([num2str(i)])) == 1);
            short_vals = removevars(short_vals, short_vals.Properties.VariableNames(colsToRemove));
            len=len-length(colsToRemove);
        end
        short_len=max(find(contains(short_vals.Properties.VariableNames, 'Graph')))+1;
        % Remove all features outside length of word for OR
        in=56; % width of the OR data
        for i=long_OR_Length+1:13
            colsToRemove = find(contains(long_vals.Properties.VariableNames(long_len:end-34), strcat([num2str(i)])) == 1)+long_len-1;
            long_vals = removevars(long_vals, long_vals.Properties.VariableNames(colsToRemove));
            in=in-length(colsToRemove);
        end

        long_len=max(find(contains(long_vals.Properties.VariableNames, 'OR')))+1;

        in=56; % width of the OR data
        for i=short_OR_Length:13
            colsToRemove = find(contains(short_vals.Properties.VariableNames(short_len:end-34), strcat([num2str(i)])) == 1)+short_len-1;
            short_vals = removevars(short_vals, short_vals.Properties.VariableNames(colsToRemove));
            in=in-length(colsToRemove);
        end

        short_len=max(find(contains(short_vals.Properties.VariableNames, 'OR')))+1;

        in=36; % width of the letter data
        for i=short_Ltr_Length+1:17
            colsToRemove = find(contains(short_vals.Properties.VariableNames(short_len:end), strcat([num2str(i)])) == 1)+short_len-1;
            short_vals = removevars(short_vals, short_vals.Properties.VariableNames(colsToRemove));
            in=in-length(colsToRemove);
        end

        in=36; % width of the letter data
        for i=long_Ltr_Length+1:17
            colsToRemove = find(contains(long_vals.Properties.VariableNames(long_len:end), strcat([num2str(i)])) == 1)+long_len-1;
            long_vals = removevars(long_vals, long_vals.Properties.VariableNames(colsToRemove));
            in=in-length(colsToRemove);
        end

        % Take the minimum values before removing to check if they are all the same later
        if contains(mtype, 'min')
            Long_GP_Prob=min(table2array(long_vals(1,find(startsWith(long_vals.Properties.VariableNames, 'GP') & contains(long_vals.Properties.VariableNames, 'Prob')))));
            Short_GP_Prob= min(table2array(short_vals(1,find(startsWith(short_vals.Properties.VariableNames, 'GP') & contains(short_vals.Properties.VariableNames, 'Prob')))));

            Long_GP_Freq=min(table2array(long_vals(1,find(startsWith(long_vals.Properties.VariableNames, 'GP') & contains(long_vals.Properties.VariableNames, 'Freq')))));
            Short_GP_Freq=min(table2array(short_vals(1,find(startsWith(short_vals.Properties.VariableNames, 'GP') & contains(short_vals.Properties.VariableNames, 'Freq')))));

            Long_G_Freq=min(table2array(long_vals(1,find(startsWith(long_vals.Properties.VariableNames, 'Graph') & contains(long_vals.Properties.VariableNames, 'Freq') & ~contains(long_vals.Properties.VariableNames, 'GP')))));
            Short_G_Freq=min(table2array(short_vals(1,find(startsWith(short_vals.Properties.VariableNames, 'Graph') & contains(short_vals.Properties.VariableNames, 'Freq') & ~contains(short_vals.Properties.VariableNames, 'GP')))));

            Long_P_Freq=min(table2array(long_vals(1,find(startsWith(long_vals.Properties.VariableNames, 'P') & contains(long_vals.Properties.VariableNames, 'Freq')))));
            Short_P_Freq=min(table2array(short_vals(1,find(startsWith(short_vals.Properties.VariableNames, 'P') & contains(short_vals.Properties.VariableNames, 'Freq')))));
        end

        % ################## Loop to remove the same GP from the words ##################
        for i=1:short_Length

            % Take the columns of feature # i in the shorter word
            columnsToCompare1 = find(startsWith(short_vals.Properties.VariableNames, strcat('GP', num2str(i), '_')) | ...
                startsWith(short_vals.Properties.VariableNames, strcat('P', num2str(i), '_')) | ...
                startsWith(short_vals.Properties.VariableNames, strcat('Graph', num2str(i), '_')) == 1);

            % Remove the cell that has the position(the text messes up other functions)
            columnsToCompare1=columnsToCompare1(2:end);

            for j=1:long_Length

                % Take the columns of feature # j in longer word
                columnsToCompare2 = find(startsWith(long_vals.Properties.VariableNames, strcat('GP', num2str(j), '_')) | ...
                    startsWith(long_vals.Properties.VariableNames, strcat('P', num2str(j), '_')) | ...
                    startsWith(long_vals.Properties.VariableNames, strcat('Graph', num2str(j), '_')) == 1);

                % Remove the cell that has the position(the text messes up other functions)
                columnsToCompare2 = columnsToCompare2(2:end);

                % If the values are exactly the same: remove or set columns to zero
                if isequaln(short_vals(:,columnsToCompare1),long_vals(:,columnsToCompare2))
                    short_vals(:,columnsToCompare1)=[];
                    long_vals(:,columnsToCompare2)=[];
                    % end

                    difflength=difflength-2;
                end
            end
        end

        % ################## Loop to remove the same OR from the words ##################
        for i=1:short_OR_Length

            % Take the columns of feature # i in the shorter word
            columnsToCompare1Onset = find(contains(short_vals.Properties.VariableNames, strcat('OR', num2str(i), '_')));

            for j=1:long_OR_Length

                % Take the columns of feature # i in the shorter word
                columnsToCompare2Onset = find(contains(long_vals.Properties.VariableNames, strcat('OR', num2str(j), '_')));

                % If the values are exactly the same: remove or set columns to zero
                if isequaln(short_vals(:,columnsToCompare1Onset),long_vals(:,columnsToCompare2Onset)) & ~isempty(columnsToCompare1Onset)
                    short_vals(:,columnsToCompare1Onset)=[];
                    long_vals(:,columnsToCompare2Onset)=[];
                    difflength=difflength-2;
                end
            end
        end

        ignore=[];
        % ################## Loop to remove the same Ltr from the words ##################
        for i=1:short_Ltr_Length

            % Take the columns of feature # i in the shorter word
            columnsToCompare1 = find(contains(short_vals.Properties.VariableNames, strcat('Ltr', num2str(i))));
            columnsToCompare1=short_vals.Properties.VariableNames(columnsToCompare1(1:2));
            for j=1:long_Ltr_Length-length(ignore)
                if any(j==ignore)
                    continue
                end
                % i=3, j=6 is the problem
                % Take the columns of feature # i in the shorter word
                columnsToCompare2 = find(contains(long_vals.Properties.VariableNames, strcat('Ltr', num2str(j))));
                columnsToCompare2=long_vals.Properties.VariableNames(columnsToCompare2(1:2));
                % If the values are exactly the same: remove or set columns to zero
                if isequaln(short_vals.(columnsToCompare1{1}),long_vals.(columnsToCompare2{1})) & isequaln(short_vals.(columnsToCompare1{2}),long_vals.(columnsToCompare2{2}))
                    short_vals(:,columnsToCompare1)=[];
                    long_vals(:,columnsToCompare2)=[];
                    difflength=difflength-2;
                    ignore(end+1)=j;
                    break
                end
            end
        end


        for i=1:length(measures)

            short_lower_tertile_thresh=lower_tertile(startsWith(newdata.Properties.VariableNames, measures{i}));
            short_upper_tertile_thresh=upper_tertile(startsWith(newdata.Properties.VariableNames, measures{i}));
            long_lower_tertile_thresh=lower_tertile(startsWith(newdata.Properties.VariableNames, measures{i}));
            long_upper_tertile_thresh=upper_tertile(startsWith(newdata.Properties.VariableNames, measures{i}));


            short_array=table2array(short_vals(1,startsWith(short_vals.Properties.VariableNames, array_terms{i}) & contains(short_vals.Properties.VariableNames, array_terms{i+match})));
            long_array=table2array(long_vals(1,startsWith(long_vals.Properties.VariableNames, array_terms{i}) & contains(long_vals.Properties.VariableNames, array_terms{i+match})));
            long_array=long_array(~isnan(long_array));
            long_array=long_array(~long_array==0);
            short_array=short_array(~isnan(short_array));
            short_array=short_array(~short_array==0);
            short_unit=short_vals.(measures{i});
            long_unit=long_vals.(measures{i});

            short_index=find(short_array==short_unit);
            long_index=find(long_array==long_unit);

            if short_lower_tertile_thresh>short_unit & long_lower_tertile_thresh>long_unit
                results.(names{i})(wp_tally(t, 2), wp_tally(t, 1)) = 0;
                calcvals.(names{i})('Lower') = double(calcvals.(names{i})('Lower')) + 1;
            elseif short_upper_tertile_thresh<short_unit & long_upper_tertile_thresh<long_unit
                results.(names{i})(wp_tally(t, 2), wp_tally(t, 1)) = 1;
                calcvals.(names{i})('Upper') = double(calcvals.(names{i})('Upper')) + 1;
            else
                results.(names{i})(wp_tally(t, 2), wp_tally(t, 1)) = 0.5;
                calcvals.(names{i})('Middle') = double(calcvals.(names{i})('Middle')) + 1;
            end
        end

    end
    
    
    % Forgot to do this before and was too lazy to inculcate it into the
    % for loop
    

    wp_tally = nchoosek(1:numOfWords, 2);
    if ~within
        lower_tertile=quantile(freq.('Freq_SUBTLEXUS'), 1/3);
        upper_tertile=quantile(freq.('Freq_SUBTLEXUS'), 2/3);
    else
        lower_tertile=quantile(newfreq.('Freq_SUBTLEXUS'), 1/3);
        upper_tertile=quantile(newfreq.('Freq_SUBTLEXUS'), 2/3);
        
    max_tally=max(newfreq.('Freq_SUBTLEXUS'));
    W_Freq=zeros(numOfWords);
    for t = 1:size(wp_tally, 1)
        % Load in word
        word1 = char(wordlist(wp_tally(t, 1), 1)); % grabs word 1 from wordlist
        word2 = char(wordlist(wp_tally(t, 2), 1)); % grabs word 2 from wordlist
        if length(word1)>=length(word2)
            longer_word=word1;
            shorter_word=word2;
        else
            longer_word=word2;
            shorter_word=word1;
        end

        % Get word indexes
        long_index = find(strcmp(longer_word, string(newfreq.Word)) == 1); %finding where word1 is in the unique word list
        short_index = find(strcmp(shorter_word, string(newfreq.Word)) == 1); %find word2 in unique word list
        short_unit=newfreq.("Freq_SUBTLEXUS")(short_index);
        long_unit=newfreq.("Freq_SUBTLEXUS")(long_index);

        if lower_tertile>short_unit && lower_tertile>long_unit
                    W_Freq(wp_tally(t, 2), wp_tally(t, 1)) = 0;
                elseif upper_tertile<short_unit && upper_tertile<long_unit
                    W_Freq(wp_tally(t, 2), wp_tally(t, 1)) = 1;
                else
                    W_Freq(wp_tally(t, 2), wp_tally(t, 1)) = 0.5;
        end
    end

    %%

    eDM=results;
    W_Freq=tril(W_Freq, -1);
    eDM.('W_Freq')=W_Freq;
    
    directoryPath=fullfile(w_dir, sprintf('%s', analysis_name));
    if exist(directoryPath, 'dir') ~= 7
        % If the directory doesn't exist, create it
        mkdir(directoryPath);
    end
    save(fullfile(directoryPath, 'eDM.mat'), 'eDM');
    writetable(calcvals, fullfile(directoryPath, 'eDM_Distributions.csv'), 'WriteRowNames', true);
end
