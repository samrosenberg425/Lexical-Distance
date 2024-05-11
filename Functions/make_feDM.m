function feDM = make_feDM(wordlist, analysis_name, w_dir, data, fDM, cDM, eDM)

fprintf('Making feature-experience distance matrices(feDM) (Task 4/5) \n')

%% Isolate relevant data
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
    
% Makes a string array of the wordlist
wordlist = string(data.Word(r)); %wordlist and randWords are the same
newdata=data(r,:);

%% Make allDM

allDM=struct();
f=fieldnames(eDM);
for i = 1:length(f)
    allDM.(f{i})=eDM.(f{i});
end
f=fieldnames(fDM);
for i = 1:length(f)
    allDM.(f{i})=fDM.(f{i});
end


%% feDM(old ntm)
GP=allDM.("GP_Freq").*allDM.("GP_ED");
G=allDM.("G_Freq").*allDM.("G_ED");
P=allDM.("P_Freq").*allDM.("P_ED");
OR=allDM.("OR_Freq").*allDM.("OR_ED");
OR_Prob=allDM.("OR_Prob").*allDM.("OR_ED");
GP_Prob=allDM.("GP_Prob").*allDM.("GP_ED");
Ltr=allDM.("Ltr_Freq").*allDM.("Ltr_ED");
feDM=struct("GP", GP, "G", G, "P", P, ...
    "OR", OR, "OR_Prob", OR_Prob, "GP_Prob", GP_Prob, "Ltr", Ltr);

f=fieldnames(feDM);
for i = 1:length(f)
    allDM.(f{i})=feDM.(f{i});
end

save(fullfile(analysis_name, 'allDM.mat'), 'allDM')
save(fullfile(analysis_name,'feDM.mat'), 'feDM')


end