%Script for mining first 190 frames from brain slice timeseries imaging to
%get data without stimulation. This data will then be mined for spontaneous
%activity.
maxFrameNum = 190; %Limit to frames prior to stim
imageStackInfo.stimFrame = 200;
imageStackInfo.gridSize = 25;
imageStackInfo.frameRate = str2double(FrameRateHzEditField.Value);
selpath = uigetdir;
tifFiles = dir(strcat(selpath,'/*.tif'));

for file = 1:size(tifFiles,1)
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load substack
    clc
    disp("Processing File " + file + " of " + size(tifFiles,1))
    file = tifFiles(file).name;
    path = selpath;
    imageStackInfo.fileName = file;
    imageStackInfo.pathName = path;
    file = strcat(path,'/',file);
    fileinfo = imfinfo(file);
    imageStackInfo.height=fileinfo(1).Height;
    imageStackInfo.width=fileinfo(1).Width;
    imageStackInfo.numFrames=size(fileinfo,1);
    imageStack=zeros(imageStackInfo.height,...
    imageStackInfo.width,imageStackInfo.numFrames);
    for j=1:maxFrameNum %Limit frames to before stimulation occurs 
        imageStack(:,:,j)=imread(file,j); 
    end
    imageStack = imageStack;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process ROIs

        roiMask = generateGrid(app);
        
        imagestack = app.imageStack;
    roiMask = app.roiMask;
    frameRate = app.imageStackInfo.frameRate;
    frames = app.imageStackInfo.numFrames;
    measuredValues = struct('MeanIntensity',zeros(1,size(imagestack,3)),...
        'Area',zeros(1,size(imagestack,3)),...
        'CenterX',zeros(1,size(imagestack,3)),...
        'CenterY',zeros(1,size(imagestack,3)),...
        'zscore',zeros(1,size(imagestack,3)),...
        'dF',zeros(1,size(imagestack,3)),...
        'dFdetrend',zeros(1,size(imagestack,3)),...
        'auc',zeros(1));
    %Make progress bar
    f = app.NanosensorImagingAppUIFigure;
    d = uiprogressdlg(f,'Title','Collecting ROI Data',...
    'Message','Please Wait','Cancelable','on');
    %Process ROIs frame by frame
    for frame = 1:frames
        if d.CancelRequested
            break
        end
        d.Value = frame./frames; %Update progress bar
        image=imagestack(:,:,frame);
        stats=regionprops(roiMask,image,'MeanIntensity','WeightedCentroid','Area','PixelValues');
        numROIs=length(stats);
        for j=1:numROIs            
            measuredValues(j).MeanIntensity(frame)=stats(j).MeanIntensity;
            measuredValues(j).Area(frame)=stats(j).Area;
            measuredValues(j).CenterX(frame)=stats(j).WeightedCentroid(1);
            measuredValues(j).CenterY(frame)=stats(j).WeightedCentroid(2);
            measuredValues(j).PixelValues(:,frame)=stats(j).PixelValues;
            measuredValues(j).MedianIntensity(frame)=median(stats(j).PixelValues);
            measuredValues(j).SumIntensity(frame)=sum(stats(j).PixelValues);
            measuredValues(j).ROInum=j; 
        end
    end
    %Make progress bar
    f = app.NanosensorImagingAppUIFigure;
    d = uiprogressdlg(f,'Title','Normalizing Timeseries Traces',...
    'Message','Please Wait','Cancelable','on');
    for roi=1:numROIs
        if d.CancelRequested
            break
        end
        d.Value = roi./numROIs; %Update progress bar
        trace=measuredValues(roi).MeanIntensity;
        window = 2*(floor((35*frameRate)/2))+1; %Use a 35 second smoothing window, ensuring it is odd number;
        filtTrace = medfilt1(trace,window,'truncate');
        baselinedData = trace-filtTrace;
        %Calculate df/f0 using f0 as the mean intensity of the 3 seconds prior to
        %stimulation
        stimFrame = app.imageStackInfo.stimFrame;
        f0=mean(trace(1:stimFrame-floor(3*frameRate)));
        df1 = (trace-f0)./f0;
        measuredValues(roi).dF = df1;
        %Calculate df/f0 where f0 is calculated from the median filter smoothed
        %trace. I.e. at each time point of the trace, f is subtracted and
        %normalized by the value of the median filter smoothed trace at the
        %corresponding time point. This corrects for drifting baselines.
        df2 = (trace-filtTrace)./filtTrace;
        measuredValues(roi).dFdetrend = df2;
        %Calculate zscore using the first 5 seconds of the baseline
        %corrected trace
        noise = std(baselinedData(1:floor(5*frameRate)));
        zscore = baselinedData./noise;
        measuredValues(roi).zscore = zscore;
        %Calculate AUC for the detrended dF/F curve. Use time
        %interval from stimulus to stimulus+5seconds. Smooth curve and then
        %offset by the min value.
        traceAUC = smooth(df2(stimFrame:stimFrame+floor(5*frameRate)),5);
        traceAUC=traceAUC-min(traceAUC);
        measuredValues(roi).auc = sum(traceAUC);
    end  
end
        results.roiData = processROI(app);
        
        
        
        results.roiMask = roiMask;
        results.imageStackInfo = imageStackInfo;
        results.imageStackInfo.firstFrame = mean(imageStack(:,:,1:5),3);
        
        stimFrame = imageStackInfo.stimFrame;
        frameRate = imageStackInfo.frameRate;
        results.fitData = struct();
        f = NanosensorImagingAppUIFigure;
        d = uiprogressdlg(f,'Title','Identifying Spikes and Curve Fitting',...
            'Message','Please Wait','Cancelable','on');
        for i = 1:length(results.roiData)

            
            traceData = results.roiData(i).dFdetrend;
            [results.fitData(i).fitResults,...
                results.fitData(i).rootResNorm,...
                results.fitData(i).fitPlot,...
                results.fitData(i).spikeLocs,...
                results.fitData(i).significance]...
                = fitExponentialFunction(traceData,stimFrame,frameRate);
        endsummaryData = generateSummary(results);        

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Export Results        
    fileToSave = strcat(app.imageStackInfo.pathName,'/',app.imageStackInfo.fileName);
    results = app.results;
    save(strcat(fileToSave(1:end-4),'.mat'),'results');
    %Create array of dF/F values
    df = zeros(length(results.roiData(1).dFdetrend),length(results.roiData));
    for i=1:length(results.roiData)
        df(:,i)=results.roiData(i).dFdetrend;
    end
    writematrix(df,strcat(fileToSave(1:end-4),'.xlsx'),'Sheet','dF_F0 Detrend')        
        generateReport(app);
        end
        
end