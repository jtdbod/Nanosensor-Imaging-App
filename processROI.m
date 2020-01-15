function [measuredValues]=processROI(app)
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
    f = app.UIFigure;
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
    %Calculate dF/F using average of 30 previous frames
    %Make progress bar
    f = app.UIFigure;
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
        noise = std(baselinedData(1:stimFrame-floor(5*frameRate)));
        zscore = baselinedData./noise;
        measuredValues(roi).zscore = zscore;
        %Calculate AUC for the for the detrended dF/F curve. Use time
        %interval from stimulus to stimulus+5seconds.
        measuredValues(roi).auc = sum(df2(stimFrame:stimFrame+floor(5*frameRate)));
    end  
    disp('Done');
end