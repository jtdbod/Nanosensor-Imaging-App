function [dataFill] = generateSummary(results)
%{
Generate the following vales and STD (if applicable) and display in GUI and export to file
> Number of ROIs
> Number of significant ROIs
> Mean peak dF/F
> Mean tau-on
> Mean tau-off
> Mean AUC
> Peak dF/F
%}
numRois = size(results.roiData,2);
sigIndex = find([results.fitData(:).significance]);
numSigs = length(sigIndex);
pctSig = numSigs./numRois;
fitResults = reshape([results.fitData(:).fitResults].',4,[])';
tau_on = nanmean(fitResults(:,2));
tau_on_std = nanstd(fitResults(:,2));
tau_off = nanmean(fitResults(:,3));
tau_off_std = nanstd(fitResults(:,3));
meanAuc = nanmean([results.roiData(sigIndex).auc]);
meanAuc_std = nanstd([results.roiData(sigIndex).auc]);
dFdetrend = reshape([results.roiData(sigIndex).dFdetrend].',length(results.roiData(1).dFdetrend),[])';
frameRate = results.imageStackInfo.frameRate;
stimFrame = results.imageStackInfo.stimFrame;
if ~results.imageStackInfo.containsStim
    maxdFoverF = 0;
    maxdFoverF_std = 0;
else
    maxdFoverF = nanmean(max(dFdetrend(:,stimFrame:stimFrame+floor(3*frameRate)),[],2));
    maxdFoverF_std = nanstd(max(dFdetrend(:,stimFrame:stimFrame+floor(3*frameRate)),[],2));
end
%{
dataValues = {numRois numSigs pctSig tau_on tau_off...
    meanAuc maxdFoverF};
stdValues = {'-' '-' '-' tau_on_std tau_off_std meanAuc_std maxdFoverF_std};
%}
variableNames = {'ROI Total','Signif ROIs', 'Pct Sig ROIs',...
    'Mean t On (s)','Mean t Off (s)','Mean AUC','Mean Peak dF/F'};
dataFill = table({numRois;'-'},{numSigs;'-'},...
    {pctSig;'-'}, {tau_on;tau_on_std},...
    {tau_off;tau_off_std},{meanAuc;meanAuc_std},...
    {maxdFoverF;maxdFoverF_std},'VariableNames',variableNames);

fileLocation = strcat(results.imageStackInfo.pathName,'/Results Summary.xlsx');
if exist(fileLocation,'file')==2
    T1 = readtable(fileLocation,'PreserveVariableNames',true);
    headerNames = {'File Name','Processed Timestamp','ROI Total','Significant ROIs',...
        '% Significant ROIs','Mean t_on (s)','t_on STD','Mean t_off (s)',...
        't_off STD','Mean AUC','AUC STD','Mean Peak dF/F_0','Peak dF/F_0 STD'};
    T2 = table({results.imageStackInfo.fileName},{datestr(datetime)},...
        numRois,numSigs,pctSig,tau_on,tau_on_std,...
        tau_off,tau_off_std,meanAuc,meanAuc_std,...
        maxdFoverF,maxdFoverF_std,'VariableNames',headerNames);
    writetable([T1;T2],fileLocation);
else
    headerNames = {'File Name','Processed Timestamp','ROI Total','Significant ROIs',...
        '% Significant ROIs','Mean t_on (s)','t_on STD','Mean t_off (s)',...
        't_off STD','Mean AUC','AUC STD','Mean Peak dF/F_0','Peak dF/F_0 STD'};
    T = table({results.imageStackInfo.fileName},{datestr(datetime)},...
        numRois,numSigs,pctSig,tau_on,tau_on_std,...
        tau_off,tau_off_std,meanAuc,meanAuc_std,...
        maxdFoverF,maxdFoverF_std,'VariableNames',headerNames);
    writetable([T],fileLocation);
end
end
    
    
