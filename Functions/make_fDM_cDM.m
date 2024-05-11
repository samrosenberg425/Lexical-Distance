function [fDM, cDM] = make_fDM_cDM(wordlist, analysis_name, w_dir, data, jpglove)
    %% Isolate wordlist data
    fprintf('Making feature(fDM) and control(cDM) distance matrices \n')
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
    data=data(r,:);
    
    %% Preallocate Tables

    gpTablewords = data{:, {'Word'}};% formats empty table for stimulus words, finds every pg* column, makes table of just gp
    pgmask = startsWith(data.Properties.VariableNames, 'PG') & cellfun('length', data.Properties.VariableNames) <= 4; % determines what columns in ntr_word_masterlist begin with lowercase "pg"
    Fcols = data(:, pgmask); % omits columns that do not begin with "pg"
    gpTable = [gpTablewords, table2cell(Fcols)]; % combines gpTablewords and "pg" columns and converts table to cell
    [numrowsgp, numcolsgp] = size(gpTable); %Get # of pg columns to use later in script



    ORTablewords = data{:, {'Word'}};
    ormask = (startsWith(data.Properties.VariableNames, 'OR') & ~contains(data.Properties.VariableNames, '_')); % determines what columns in ntr_word_masterlist begin with lowercase "pg"

    Fcols = data(:, ormask); % omits columns that do not begin with "pg"
    ORTable = table2cell([ORTablewords Fcols]); % combines gpTablewords and "pg" columns and converts table to cell
    [numrowsOR, numcolsOR] = size(ORTable);

    %% Calculating distance matrices

    tri_mask = tril(ones(numOfWords) > 0, -1);

    % Setting up the results table 
    Ltr_ED = zeros(numOfWords); % letter edit distance
    Sem_Corr = zeros(numOfWords); % Semtic ccorrelation
    GP_ED = zeros(numOfWords); % Grapheme-phoneme edit distance
    OR_ED = zeros(numOfWords); % Onset rime edit distance
    P_ED = zeros(numOfWords); % Phoneme edit distance
    G_ED = zeros(numOfWords); % Grapheme edit distance
    O_Neigh = zeros(numOfWords); % Orthographic neighborhood
    P_Neigh = zeros(numOfWords); % Phonnologic neighborhood
    PG_Neigh = zeros(numOfWords); % Phoneme-Grapheme Neeighborhood
    Sem_NeighDen = zeros(numOfWords); % Semantic neighborhood density
    Bigram_Freq = zeros(numOfWords);% Bigram frequency
    Biphon_Prob = zeros(numOfWords); % Biphone probability
    Ltr_Num = zeros(numOfWords); % Number of letters
    Syll_Num = zeros(numOfWords); % Number of Syllables


    word_index = cell(numOfWords, numOfWords); %word index
    word_index(:) = {'0'};%word index

    % Get uniqe list of word pairings indices
    wp_tally = nchoosek(1:numOfWords, 2);

    %finding the word pairings and their distances(column 1 and column 2
    %are the indexes of the matched words)

    for t = 1:size(wp_tally, 1)

        fprintf("Number of runs: %d of %d (Making fDM+cDM - Task 1+2/5) \n", t, size(wp_tally, 1))
        word1 = wordlist(wp_tally(t, 1), 1); % grabs word 1 from wordlist
        word2 = wordlist(wp_tally(t, 2), 1); % grabs word 2 from wordlist

        if (word1 < word2) %finding which word comes first in the alphabet
            lessAlpha = word1;
            moreAlpha = word2;
        else
            lessAlpha = word2;
            moreAlpha = word1;
        end

        % ORTHOGRAPHIC EDIT DISTANCE
        wLength(1) = strlength(word1);
        wLength(2) = strlength(word2);
        Ltr_ED(wp_tally(t, 2), wp_tally(t, 1)) = editDistance(word1, word2, 'SwapCost', 1) / max(wLength);

        % GP EDIT DISTANCE - make function
        index1 = find(strcmp(word1, string(data.Word)) == 1); %finding where word1 is in the unique word list
        index2 = find(strcmp(word2, string(data.Word)) == 1); %find word2 in unique word list

        if isempty(index1) == 0 && isempty(index2) == 0 %check if string was found
            string1gp = strjoin(gpTable(index1, 2:end)); % condenses all 29 pg columns from gpTable into one string for word1
            string1gp(string1gp == '+') = []; % removes all plus signs
            word1GP = tokenizedDocument(string1gp); % converts to tokenized document (splits each unit into separate cells)

            string2gp = strjoin(gpTable(index2, 2:end)); % condenses all 29 pg columns from gpTable into one string for word1
            string2gp(string2gp == '+') = []; % removes all plus signs
            word2GP = tokenizedDocument(string2gp); % converts to tokenized document (splits each unit into separate cells)

            gpDistance = editDistance(word1GP, word2GP, 'SwapCost', 1); % gives edit distance for words 1 and 2 gps

            gpLength(1) = size(tokenDetails(word1GP), 1);
            gpLength(2) = size(tokenDetails(word2GP), 1);

            gpEditDistance = gpDistance(1, 1) / max(gpLength);

            GP_ED(wp_tally(t, 2), wp_tally(t, 1)) = gpEditDistance;
        end

        % Onset rimes EDIT DISTANCE
        index1 = find(strcmp(word1, string(data.Word)) == 1); %finding where word1 is in the unique word list
        index2 = find(strcmp(word2, string(data.Word)) == 1); %find word2 in unique word list

        if isempty(index1) == 0 && isempty(index2) == 0 %check if string was found
            count=1;
            for n = 1:numcolsOR
                string1OR = string(strcat(ORTable(index1, n), ORTable(index1, n)));
                string1OR = strrep(string1OR, '+', '');
                string1ORfull(1, count) = string1OR;
                string2OR = string(strcat(ORTable(index2, n), ORTable(index2, n)));
                string2OR = strrep(string2OR, '+', '');
                string2ORfull(1, count) = string2OR;
                count=count+1;
            end

            string1ORtok = tokenizedDocument(string1ORfull, 'TokenizeMethod', 'none');
            string2ORtok = tokenizedDocument(string2ORfull, 'TokenizeMethod', 'none');
            ORDistance = editDistance(string1ORtok, string2ORtok, 'SwapCost', 1);
            clear string1ORfull;
            clear string2ORfull;
            ORNLetters(1) = size(tokenDetails(string1ORtok), 1);
            ORNLetters(2) = size(tokenDetails(string2ORtok), 1);
            OREditDistance = ORDistance(1, 1) / max(ORNLetters);

            OR_ED(wp_tally(t, 2), wp_tally(t, 1)) = OREditDistance;
        end

        glove_index1=find(strcmp(word1, string(jpglove.(1))) == 1);
        glove_index2=find(strcmp(word2, string(jpglove.(1))) == 1);
        % SEMANTIC EDIT DISTANCE - change to use file, not variables from workspace
        word1Vars = jpglove(glove_index1, 2:end); % grabs all glove variables for word 1
        word2Vars = jpglove(glove_index2, 2:end); % grabs all glove variables for word 2
        if isempty(table2array(word1Vars))==0 && isempty(table2array(word2Vars))==0 %grabs correlation coefficient
            SemCorr = corrcoef(table2array(word1Vars), table2array(word2Vars)); %grabs correlation coefficient
            Sem_Corr(wp_tally(t, 2), wp_tally(t, 1)) = 1 - SemCorr(1, 2); % records correlation
        else
            SemCorr(wp_tally(t, 2), wp_tally(t, 1))=NaN;
            break
        end
            
        index1 = find(strcmp(word1, string(data.Word)) == 1); %finding where word1 is in the unique word list
        index2 = find(strcmp(word2, string(data.Word)) == 1);
        % PHONEME UNIT AND GRAPHEME UNIT EDIT DISTANCE (separated, not P+G)
        if isempty(index1) == 0 && isempty(index2) == 0 %check if string was found
            phonemeWord1 = string; % sets up four variables with empty strings
            graphemeWord1 = string;
            phonemeWord2 = string;
            graphemeWord2 = string;

            for m = 2:numcolsgp %Read the number of columns in gpTable (don't include words column)

                pString1 = strjoin(gpTable(index1, 2:end)); % check if p correct
                pgWord1 = gpTable{index1, m};
                pWord1 = extractBefore(pgWord1, "+"); %grabs just phoneme (before plus)
                phonemeWord1 = append(phonemeWord1, pWord1, ' '); % puts phonemes into one string
                pgWord1 = gpTable{index1, m};
                gWord1 = extractAfter(pgWord1, "+"); %grabs just grapheme (after plus)
                graphemeWord1 = append(graphemeWord1, gWord1, ' '); % puts graphemes into one string
                pString2 = strjoin(gpTable(index2, 2:end)); % check if p correct
                pgWord2 = gpTable{index2, m};
                pWord2 = extractBefore(pgWord2, "+");
                phonemeWord2 = append(phonemeWord2, pWord2, ' ');
                pgWord2 = gpTable{index2, m};
                gWord2 = extractAfter(pgWord2, "+");
                graphemeWord2 = append(graphemeWord2, gWord2, ' ');

            end

            % creates tokenized documents
            phonemeWord1 = tokenizedDocument(phonemeWord1);
            graphemeWord1 = tokenizedDocument(graphemeWord1);
            phonemeWord2 = tokenizedDocument(phonemeWord2);
            graphemeWord2 = tokenizedDocument(graphemeWord2);

            % calculates edit distances for phonemes and graphemes
            phonemeNLetters(1) = size(tokenDetails(phonemeWord1), 1);
            phonemeNLetters(2) = size(tokenDetails(phonemeWord2), 1);

            graphemeNLetters(1) = size(tokenDetails(graphemeWord1), 1);
            graphemeNLetters(2) = size(tokenDetails(graphemeWord2), 1);

            pEditDistance = editDistance(phonemeWord1, phonemeWord2, 'SwapCost', 1);
            gEditDistance = editDistance(graphemeWord1, graphemeWord2, 'SwapCost', 1);
            phonemeEditDistance = pEditDistance(1, 1) / max(phonemeNLetters);
            graphemeEditDistance = gEditDistance(1, 1) / max(graphemeNLetters);

            P_ED(wp_tally(t, 2), wp_tally(t, 1)) = phonemeEditDistance; % records phonemes and graphemes edit distances
            G_ED(wp_tally(t, 2), wp_tally(t, 1)) = graphemeEditDistance;
        end

        % SUM DISTANCES
        index1 = find(strcmp(word1, string(data.Word)) == 1); %finding where word1 is in the unique word list
        index2 = find(strcmp(word2, string(data.Word)) == 1);

        O_Neigh(wp_tally(t, 2), wp_tally(t, 1)) = data.OLD20(index1) + data.OLD20(index2);
        P_Neigh(wp_tally(t, 2), wp_tally(t, 1)) = data.PLD20(index1) + data.PLD20(index2);
        PG_Neigh(wp_tally(t, 2), wp_tally(t, 1)) = data.Phonographic_N(index1) + data.Phonographic_N(index2);
        Sem_NeighDen(wp_tally(t, 2), wp_tally(t, 1)) = data.Sem_N_D(index1) + data.Sem_N_D(index2);
        Bigram_Freq(wp_tally(t, 2), wp_tally(t, 1)) = data.BigramF_Avg_C_Log(index1) + data.BigramF_Avg_C_Log(index2);
        Biphon_Prob(wp_tally(t, 2), wp_tally(t, 1)) = data.BiphonP_Un(index1) + data.BiphonP_Un(index2);


        % SUBTRACTION DISTANCES
        index1 = find(strcmp(word1, string(data.Word)) == 1); %finding where word1 is in the unique word list
        index2 = find(strcmp(word2, string(data.Word)) == 1);

        Ltr_Num(wp_tally(t, 2), wp_tally(t, 1)) = abs(data.N_Ltr(index1) - data.N_Ltr(index2));
        Syll_Num(wp_tally(t, 2), wp_tally(t, 1)) = abs(data.N_Ltr(index1) - data.N_Ltr(index2));

        % get word distance
      word_index{wp_tally(t, 2), wp_tally(t, 1)} = sprintf('%s-%s',data.Word{index1},data.Word{index2});
    end

    %% Save outputs

    fDM=struct("G_ED", G_ED, "P_ED", P_ED, "GP_ED", GP_ED, "OR_ED", OR_ED, "Ltr_ED", Ltr_ED, "W_ED", tril(ones(numOfWords), -1), "Sem", Sem_Corr);
    cDM=struct("Ltr_Num", Ltr_Num, "Syll_Num", Syll_Num);
    directoryPath=fullfile(w_dir, sprintf('%s', analysis_name));
    if exist(directoryPath, 'dir') ~= 7
        % If the directory doesn't exist, create it
        mkdir(directoryPath);
    end
    save(fullfile(directoryPath, 'fDM.mat'), 'fDM');
    save(fullfile(directoryPath, 'cDM.mat'), 'cDM');

end
