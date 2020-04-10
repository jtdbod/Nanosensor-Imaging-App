function [] = batchProcessTifs(app)

selpath = uigetdir;
tifFiles = dir(strcat(selpath,'/*.tif'));

for file = 1:size(tifFiles,1)
    clc
    disp("Processing File " + file + " of " + size(tifFiles,1))
    FileName = tifFiles(file).name;
    PathName = selpath;
    if FileName==0
        %User cancelled open command. Do nothing.
        error('Cancelled by user or no TIF files found');
    else
        loadTifStack(app,FileName,PathName);
        app.CurrentFileTextArea.Value = app.imageStackInfo.fileName;
        
        app.imageStackInfo.stimFrame = str2double(app.StimulusFrameNumberEditField.Value);
        app.imageStackInfo.gridSize = str2double(app.GridSizepixelsEditField.Value);
        app.imageStackInfo.frameRate = str2double(app.FrameRateHzEditField.Value);
        app.roiMask = generateGrid(app);
        app.results.roiData = processROI(app);
        app.results.roiMask = app.roiMask;
        app.results.imageStackInfo = app.imageStackInfo;
     app.results.imageStackInfo.firstFrame = mean(app.imageStack(:,:,1:5),3);
        
        stimFrame = app.imageStackInfo.stimFrame;
        frameRate = app.imageStackInfo.frameRate;
        app.results.fitData = struct();
        f = app.NanosensorImagingAppUIFigure;
        d = uiprogressdlg(f,'Title','Identifying Spikes and Curve Fitting',...
            'Message','Please Wait','Cancelable','on');
        for i = 1:length(app.results.roiData)
            if d.CancelRequested
                break
            end
            d.Value = i./length(app.results.roiData);
            traceData = app.results.roiData(i).dFdetrend;
            [app.results.fitData(i).fitResults,...
                app.results.fitData(i).rootResNorm,...
                app.results.fitData(i).fitPlot,...
                app.results.fitData(i).spikeLocs,...
                app.results.fitData(i).significance]...
                = fitExponentialFunction(traceData,stimFrame,frameRate);
        end
        summaryData = generateSummary(app.results);
        app.UISummaryTable.Data = summaryData;
        
        exportResults(app);
        if ~app.NoStimulusCheckBox.Value
        generateReport(app);
        end
    end

end
