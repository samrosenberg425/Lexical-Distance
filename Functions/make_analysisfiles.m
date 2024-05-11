function make_analysisfiles(wordlist, analysis_name, w_dir, corr_type, mat2partial, mat2residual, WithinPartial)


    [x, y] = size(wordlist);
    if x>y
        numOfWords=x;
    else 
        numOfWords=y;
    end

    %% Analysis 1 
    % All variables correlations to each other
    tri_mask=logical(tril(ones(numOfWords), -1));
    Partial_Mat=mat2partial;
    f=fieldnames(Partial_Mat);
    side=width(Partial_Mat.(f{1}));
    len=side*(side-1)/2;
    Always_Partial_Vec=zeros(len, length(f));
    for i=1:length(f)
        Always_Partial_Vec(:,i)=Partial_Mat.(f{i})(tri_mask);
    end
    
    
    Original_Mat=mat2residual;
    Analysis_Residuals=struct();
    f=fieldnames(mat2residual);
    for i=1:length(f)
        Analysis_Residuals.(f{i})=zeros(numOfWords);
    end
    corr_table=zeros(length(f));
    p_table=zeros(length(f));
    

    for i=1:length(f)
        % Preallocate matrix for residuals
        res_mat = zeros(numOfWords);
        % Isolate matrix having other values partialled out
        mat = Original_Mat.(f{i});
        Y = mat(tri_mask);
        count=1;
        % Make covariate matrix - X (aka all other matrices in Analysis1
        % struct+Ltr_Num)
        if WithinPartial==1
            for j=1:length(f)
                if j==i
                    continue
                else
                    reg=(Original_Mat.(f{j})(tri_mask));
                    X(:,count)=reg;
                    count=count+1;
                end
            end
            X = [X, Always_Partial_Vec];
        else
            X = [Always_Partial_Vec];
        end
        
        % Make a linear model with all other matrices+Ltr_Num rank ordered 
        % and partialled out
        lm = fitlm(X, Y);

        % Save the residuals in an output matrix
        Analysis_Residuals.(f{i})(tri_mask)=lm.Residuals.Raw;

        clear X
    end



    pairs=nchoosek(1:length(f), 2);
    for i=1:length(pairs)
        mat1=Analysis_Residuals.(f{pairs(i,1)});
        mat2=Analysis_Residuals.(f{pairs(i,2)});
        [rho, pval] = corr(mat1(tri_mask), mat2(tri_mask), 'Type', corr_type);
        corr_table(pairs(i,2), pairs(i,1))=rho;
        p_table(pairs(i,2), pairs(i,1))=pval;
    end

    An_corr_table=array2table(corr_table, 'VariableNames', f, 'RowNames', f);
    An_p_table=array2table(p_table, 'VariableNames', f, 'RowNames', f);
    

    %%  Write data 
    filename = sprintf('%s_Residual_%s_Correlations.xlsx', analysis_name, corr_type); % Define the Excel file name
    outpath=fullfile(w_dir, analysis_name);
    if ~exist(outpath)
        mkdir(outpath)
    end
    filepath=fullfile(outpath, filename);

    sheet = 1; % Define which sheet to write to
    startRow = 2; % Initial start row for the first table
    range = sprintf('A%d', 1);
    tableName = sprintf('%s %s Correlation Table', analysis_name, corr_type);
    blank={'', '', ''};
    T=table(text, 'VariableNames', {tableName});
    writetable(T, filepath, 'Sheet', sheet, 'Range', range, 'WriteRowNames', 1, 'WriteVariableNames', 1);

    % Evaluate the table name to get the table variable
    tableVar = (An_corr_table);

    % Define the range to write the current table
    range = sprintf('A%d', startRow);
    % Write the table to the Excel file
    writetable(tableVar, filepath, 'Sheet', sheet, 'Range', range, 'WriteRowNames', 1, 'WriteVariableNames', 1);
        
    startRow=startRow+height(corr_table)+3;
    
    range = sprintf('A%d', startRow);
    tableName = sprintf('%s P Value Table', analysis_name);
    blank={'', '', ''};
    T=table(text, 'VariableNames', {tableName});
    writetable(T, filepath, 'Sheet', sheet, 'Range', range, 'WriteRowNames', 1, 'WriteVariableNames', 1);
    
    startRow=startRow+1;
    % Evaluate the table name to get the table variable
    tableVar = (An_p_table);
    % Define the range to write the current table
    range = sprintf('A%d', startRow);
    writetable(tableVar, filepath, 'Sheet', sheet, 'Range', range, 'WriteRowNames', 1, 'WriteVariableNames', 1);
    save(fullfile(outpath, sprintf('%s_Residuals.mat', analysis_name)), 'Analysis_Residuals');

end