%%
%Process .mat file to individual ROI data to CSV.

matFiles = dir('*.mat');

for file = 1:size(matFiles,1)
    clc
    disp(['Processing file ',num2str(file),' of ',num2str(size(matFiles,1))])
    FileName = matFiles(file).name;
    current_path = pwd;
    load(strcat(current_path,'/',FileName))
    %sigIndex = find([results.fitData(:).significance]);
    sigIndex = 1:length([results.fitData(:).significance]);
    stimFrame = results.imageStackInfo.stimFrame;
    frameRate = results.imageStackInfo.frameRate;
    filename = cell(length(results.roiData),1);
	pathname = cell(length(results.roiData),1);

    df_detrend = zeros(length(results.roiData(1).dFdetrend),length(results.roiData));
    mean_intensity = zeros(length(results.roiData),1);
    tau = zeros(length(results.fitData),1);
    significance = zeros(length(results.fitData),1);

    for i = 1:length(results.roiData)
        df_detrend(:,i) = results.roiData(i).dFdetrend;
        mean_intensity(i) = mean(results.roiData(i).MeanIntensity(1:stimFrame-10));
        tau(i) = results.fitData(i).fitResults(3);
        significance(i) = results.fitData(i).significance;
        filename{i} = results.imageStackInfo.fileName;
        pathname{i} = results.imageStackInfo.pathName;
    end


    % Calculate the peak df/f0 from a dfdetrend trace
    dFdetrend = reshape([results.roiData(sigIndex).dFdetrend].',...
        length(results.roiData(1).dFdetrend),[])';
    peak_dfs = ...
        max(dFdetrend(:,stimFrame:stimFrame+floor(3*frameRate)),[],2);
    roi_num = [results.roiData(sigIndex).ROInum]';
    fileLocation = strcat(current_path,'/ROI_data.csv');
    
    if exist(fileLocation,'file')==2
        T1 = readtable(fileLocation,'ReadVariableNames',true);
        headerNames = {'File_Name','Path_Name','roi_num','Amplitude','Mean_Intensity','Tau','Significance'};
        T2 = table(filename,pathname,roi_num,...
            peak_dfs,mean_intensity,tau,significance,'VariableNames',headerNames);
        writetable([T1;T2],fileLocation);
    else
        headerNames = {'File_Name','Path_Name','roi_num','Amplitude','Mean_Intensity','Tau','Significance'};
        T = table(filename,pathname,roi_num,...
            peak_dfs,mean_intensity,tau,significance,'VariableNames',headerNames);
        writetable([T],fileLocation);
    end

end

clc
disp('Complete')