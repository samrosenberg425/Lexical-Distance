classdef MatrixSelector < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        MatrixListBoxLabel    matlab.ui.control.Label
        MatrixListBox         matlab.ui.control.ListBox
        PartialListBoxLabel   matlab.ui.control.Label
        PartialListBox        matlab.ui.control.ListBox
        ResidualsListBoxLabel matlab.ui.control.Label
        ResidualsListBox      matlab.ui.control.ListBox
        MoveRightButtonPartial matlab.ui.control.Button
        MoveRightButtonResidual matlab.ui.control.Button
        MoveLeftButtonPartial matlab.ui.control.Button
        MoveLeftButtonResidual matlab.ui.control.Button
        DoneButton            matlab.ui.control.Button
        NameLabel             matlab.ui.control.Label
        NameBox               matlab.ui.control.EditField
        CorrelationTypeLabel  matlab.ui.control.Label  
        SpearmanCheckbox      matlab.ui.control.CheckBox 
        KendallCheckbox       matlab.ui.control.CheckBox 
        WithinPartialCheckbox matlab.ui.control.CheckBox
        WithinPartialLabel    matlab.ui.control.Label
        WithinPartialLabel2   matlab.ui.control.Label
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: DoneButton
        function DoneButtonPushed(app, ~)
            allDM=evalin('base', 'allDM');
            % Get the selected matrices from the main list box
            selectedMatrices = app.MatrixListBox.Value;
            
            % Get the selected matrices for partialling and residuals
            selectedPartial = app.PartialListBox.Items;
            selectedResiduals = app.ResidualsListBox.Items;
            assignin('base', 'selectedPartial', selectedPartial);
            mat2partial=struct();
            for i=1:length(selectedPartial)
                name=selectedPartial{i};
                mat2partial.(name)=allDM.(name);
            end
            mat2residual=struct();
            for i=1:length(selectedResiduals)
                name=selectedResiduals{i};
                mat2residual.(name)=allDM.(name);
            end
            
            assignin('base', 'mat2partial', mat2partial);
            assignin('base', 'mat2residual', mat2residual);
            analysis_name=app.NameBox.Value();
            WithinPartial = app.WithinPartialCheckbox.Value;
            SpearmanChecked = app.SpearmanCheckbox.Value;
            KendallChecked = app.KendallCheckbox.Value;
            if KendallChecked==1
                corr_type='Kendall';
            elseif SpearmanChecked==1
                corr_type='Spearman';
            else
                uialert(app.UIFigure, 'No correlation type selected, please chose one:', 'Error: No corr_type')
                return
            end
            
            wordlist=evalin('base', 'wordlist');
            filepath=evalin('base', 'filepath');
            make_analysisfiles(wordlist, analysis_name, filepath, corr_type, mat2partial, mat2residual, WithinPartial)
            
            % Perform actions based on the selected matrices and selections
            % For example, display a message
            message = sprintf('Results saved to:\n %s\nSaved Residuals of: \n%s\nPartialled Out: %s\n', ...
                  fullfile(filepath, analysis_name), strjoin(selectedResiduals, ', '), strjoin(selectedPartial, ', '));
            sprintf('Analysis: %s\n', analysis_name);
            uialert(app.UIFigure, message, 'Selection Summary', 'Icon', 'info', 'CloseFcn', @(~, ~) close(app.UIFigure));
        end

        % Button pushed function: MoveRightButtonPartial
        function MoveRightButtonPartialPushed(app, ~)
            % Move selected matrices from main list box to partial list box
            selectedMatrices = app.MatrixListBox.Value;
            app.PartialListBox.Items = [app.PartialListBox.Items, selectedMatrices];
            remainingMatrices = setdiff(app.MatrixListBox.Items, selectedMatrices);
            app.MatrixListBox.Items = remainingMatrices;
        end
        % Button pushed function: MoveRightButtonResidual
        function MoveRightButtonResidualPushed(app, ~)
            % Move selected matrices from partial list box to residuals list box
            selectedMatrices = app.MatrixListBox.Value;
            app.ResidualsListBox.Items = [app.ResidualsListBox.Items, selectedMatrices];
            remainingMatrices = setdiff(app.MatrixListBox.Items, selectedMatrices);
            app.MatrixListBox.Items = remainingMatrices;
        end
        
        function MoveLeftButtonPartialPushed(app, ~)
            % Move selected matrices from main list box to partial list box
            selectedMatrices = app.PartialListBox.Value;
            app.MatrixListBox.Items = [app.MatrixListBox.Items, selectedMatrices];
            remainingMatrices = setdiff(app.PartialListBox.Items, selectedMatrices);
            app.PartialListBox.Items = remainingMatrices;
        end
        
        % Button pushed function: MoveLeftButtonResidual
        function MoveLeftButtonResidualPushed(app, ~)
            % Move selected matrices from partial list box to residuals list box
            selectedMatrices = app.ResidualsListBox.Value;
            app.MatrixListBox.Items = [app.MatrixListBox.Items, selectedMatrices];
            remainingMatrices = setdiff(app.ResidualsListBox.Items, selectedMatrices);
            app.ReisdualsListBox.Items = remainingMatrices;
        end
        
        function SpearmanChange(app, ~)
            if app.SpearmanCheckbox.Value==1
                app.KendallCheckbox.Value=0;
            elseif app.SpearmanCheckbox.Value==0
                app.KendallCheckbox.Value=1;
            end
                
        end
        
        function KendallChange(app, ~)
            if app.KendallCheckbox.Value==1
                app.SpearmanCheckbox.Value=0;
            elseif app.KendallCheckbox.Value==0
                app.SpearmanCheckbox.Value=1;
            end
        end
            

        
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app, filepath, all_mat)
            
            
            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100 100 700 280];
            app.UIFigure.Name = 'Matrix Selector';

            % Create MatrixListBoxLabel
            app.MatrixListBoxLabel = uilabel(app.UIFigure);
            app.MatrixListBoxLabel.HorizontalAlignment = 'center';
            app.MatrixListBoxLabel.FontSize = 14;
            app.MatrixListBoxLabel.Position = [20 220 150 22];
            app.MatrixListBoxLabel.Text = 'Select Matrices:';
            

            % Create MatrixListBox
            app.MatrixListBox = uilistbox(app.UIFigure);
            app.MatrixListBox.Multiselect = 'on';
            app.MatrixListBox.Position = [20 50 150 170];
            app.MatrixListBox.Items=all_mat;
            
            % Create PartialListBoxLabel
            app.PartialListBoxLabel = uilabel(app.UIFigure);
            app.PartialListBoxLabel.HorizontalAlignment = 'center';
            app.PartialListBoxLabel.FontSize = 14;
            app.PartialListBoxLabel.Position = [220 250 150 22];
            app.PartialListBoxLabel.Text = 'Matrices to Partial:';

            % Create PartialListBox
            app.PartialListBox = uilistbox(app.UIFigure);
            app.PartialListBox.Position = [220 180 150 70];
            app.PartialListBox.Items={};

            % Create ResidualsListBoxLabel
            app.ResidualsListBoxLabel = uilabel(app.UIFigure);
            app.ResidualsListBoxLabel.HorizontalAlignment = 'center';
            app.ResidualsListBoxLabel.FontSize = 14;
            app.ResidualsListBoxLabel.Position = [200 120 200 22];
            app.ResidualsListBoxLabel.Text = 'Matrices to Save Residuals of:';

            % Create ResidualsListBox
            app.ResidualsListBox = uilistbox(app.UIFigure);
            app.ResidualsListBox.Position = [220 50 150 70];
            app.ResidualsListBox.Items={};

            % Create MoveRightButtonPartial
            app.MoveRightButtonPartial = uibutton(app.UIFigure, 'push');
            app.MoveRightButtonPartial.ButtonPushedFcn = createCallbackFcn(app, @MoveRightButtonPartialPushed, true);
            app.MoveRightButtonPartial.Position = [180 220 20 22];
            app.MoveRightButtonPartial.Text = '>';

            % Create MoveRightButtonResidual
            app.MoveRightButtonResidual = uibutton(app.UIFigure, 'push');
            app.MoveRightButtonResidual.ButtonPushedFcn = createCallbackFcn(app, @MoveRightButtonResidualPushed, true);
            app.MoveRightButtonResidual.Position = [180 90 20 22];
            app.MoveRightButtonResidual.Text = '>';
            
             % Create MoveRightButtonPartial
            app.MoveLeftButtonPartial = uibutton(app.UIFigure, 'push');
            app.MoveLeftButtonPartial.ButtonPushedFcn = createCallbackFcn(app, @MoveLeftButtonPartialPushed, true);
            app.MoveLeftButtonPartial.Position = [180 190 20 22];
            app.MoveLeftButtonPartial.Text = '<';

            % Create MoveLeftButtonResidual
            app.MoveLeftButtonResidual = uibutton(app.UIFigure, 'push');
            app.MoveLeftButtonResidual.ButtonPushedFcn = createCallbackFcn(app, @MoveLeftButtonResidualPushed, true);
            app.MoveLeftButtonResidual.Position = [180 60 20 22];
            app.MoveLeftButtonResidual.Text = '<';

            % Create DoneButton
            app.DoneButton = uibutton(app.UIFigure, 'push');
            app.DoneButton.ButtonPushedFcn = createCallbackFcn(app, @DoneButtonPushed, true);
            app.DoneButton.Position = [200 10 100 22];
            app.DoneButton.Text = 'Done';
            %app.DoneButton.ButtonPushedFcn = @(~,~) DoneButtonPushed(app, [], allDM);
            
            % Name of Analysis Label
            app.NameLabel = uilabel(app.UIFigure);
            app.NameLabel.Position = [420 250 150 22]
            app.NameLabel.HorizontalAlignment = 'center';
            app.NameLabel.FontSize = 14;
            app.NameLabel.Text = 'Name of Analysis:';
            
            % Analyis Name Field
            app.NameBox = uieditfield(app.UIFigure);
            app.NameBox.Position = [420 220 150 22];
            
            % Correlation Type Label
            app.CorrelationTypeLabel = uilabel(app.UIFigure);
            app.CorrelationTypeLabel.HorizontalAlignment = 'right';
            app.CorrelationTypeLabel.FontSize = 14;
            app.CorrelationTypeLabel.Position = [420 120 150 22];
            app.CorrelationTypeLabel.Text = 'Select Correlation Type:';
            
            % Create SpearmanCheckbox
            app.SpearmanCheckbox = uicheckbox(app.UIFigure);
            app.SpearmanCheckbox.ValueChangedFcn=createCallbackFcn(app, @SpearmanChange, true);
            app.SpearmanCheckbox.Text = '   Spearman';
            app.SpearmanCheckbox.FontSize = 12;
            app.SpearmanCheckbox.Position = [440 90 90 22];
            
            % Create KendallCheckbox
            app.KendallCheckbox = uicheckbox(app.UIFigure);
            app.KendallCheckbox.ValueChangedFcn=createCallbackFcn(app, @KendallChange, true);
            app.KendallCheckbox.Text = '   Kendall';
            app.KendallCheckbox.FontSize = 12;
            app.KendallCheckbox.Position = [440 60 80 22];
            
            % Create WithinPartialCheckbox
            app.WithinPartialCheckbox = uicheckbox(app.UIFigure, 'Value', 1);
            app.WithinPartialCheckbox.Text = 'Partial Residual Matrices from one another';
            app.WithinPartialCheckbox.FontSize = 12;
            app.WithinPartialCheckbox.Position = [440 150 280 62];
            
            % Create WithinPartialLabel
            app.WithinPartialLabel = uilabel(app.UIFigure);
            app.WithinPartialLabel.HorizontalAlignment = 'center';
            app.WithinPartialLabel.FontSize = 10;
            app.WithinPartialLabel.Position = [450 140 200 42];
            app.WithinPartialLabel.Text = 'Partial out original matrices(selected to';
            
            % Create WithinPartialLabel2
            app.WithinPartialLabel2 = uilabel(app.UIFigure);
            app.WithinPartialLabel2.HorizontalAlignment = 'center';
            app.WithinPartialLabel2.FontSize = 10;
            app.WithinPartialLabel2.Position = [450 130 200 42];
            app.WithinPartialLabel2.Text = 'save residuals of) from each other ';
            
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = MatrixSelector()
            % Create UIFigure and components
            
            fileselect=false;
            while fileselect==false
                % Open DirectorySelector and wait for it to be destroyed
                hDirectorySelector = DirectorySelector();
                waitfor(hDirectorySelector);

                % Retrieve the selected filepath from the base workspace
                filepath = evalin('base', 'filepath');
                %filepath='/Users/samrosenberg/Desktop/Research/NTR/Orthogonalization/Orthogonalization_v23/test_results';
                if ~exist(fullfile(filepath, 'fDM.mat')) && ~exist(fullfile(filepath, 'eDM.mat')) && ~exist(fullfile(filepath, 'feDM.mat')) &&  ~exist(fullfile(filepath, 'cDM.mat'))
                    hlpdlg(hDirectorySelector,  sprintf('Missing proper files in: %s \n', filepath), 'Title', 'Error: Missing necessary files');
                    return
                else
                    fileselect=true;
                end
            end
            load(fullfile(filepath, 'fDM.mat'));
            load(fullfile(filepath, 'eDM.mat'));
            load(fullfile(filepath, 'feDM.mat'));
            load(fullfile(filepath, 'cDM.mat'));
            fDM_mat = strcat('fDM_', fieldnames(fDM));
            eDM_mat = strcat('eDM_', fieldnames(eDM));
            feDM_mat = strcat('feDM_', fieldnames(feDM));
            cDM_mat = strcat('cDM_', fieldnames(cDM));
            all_mat = [fDM_mat; eDM_mat; feDM_mat; cDM_mat]';
            allDM=struct();
            for i=1:length(fDM_mat)
                fname=fieldnames(fDM);
                allDM.(fDM_mat{i})=fDM.(fname{i});
            end
            for i=1:length(eDM_mat)
                fname=fieldnames(eDM);
                allDM.(eDM_mat{i})=eDM.(fname{i});
            end
            for i=1:length(feDM_mat)
                fname=fieldnames(feDM);
                allDM.(feDM_mat{i})=feDM.(fname{i});
            end
            for i=1:length(cDM_mat)
                fname=fieldnames(cDM);
                allDM.(cDM_mat{i})=cDM.(fname{i});
            end  
            wordlist=readtable(fullfile(filepath, 'wordlist.txt'), 'ReadVariableNames', false);
            wordlist=table2cell(wordlist)';
            assignin('base', 'wordlist', wordlist);
            assignin('base', 'filepath', filepath);
            assignin('base', 'allDM', allDM);
            % Create UIFigure and components
            createComponents(app, filepath, all_mat);
            
        end
    end
end