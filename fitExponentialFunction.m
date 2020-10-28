function[fitResults, rootResNorm, fitPlot, spikeLocs, significance]=fitExponentialFunction(trace,stimFrame,frameRate)
% Determine if transient occurs following stimulus. A significant transient
% is determined using a threshold method where the threshold is calculated
% using values falling below the baseline from a baseline-corrected dF/F
% trace. Assuming Gaussian noise, a symmetric distribution is constructed
% and the threshold is calculated as 3 times the standard distribution.

% RETURNS:
% fitResults = [multiplicative_factor,tau_on,tau_off,offset] 
% fitPlot = n x 2 array with col1 = time, col2 = fitted values
% spikeLocs = array containing index locations of dF/F array where significant transient occurs
% significance = boolean indicating whether a transient occured after
% stimulation

% Estimate spikes using simple gradient and gaussian noise
spikeLocs = [];
xdata = 1:length(trace);
ydata = trace;
negValues = trace(trace<0);
noise = [negValues -negValues];
threshold = 3*std(noise);
spikeLocs = find(trace>threshold);

%Fit exponential function to trace starting from stimulus if spike occurs
%within 2 seconds of stimulus or within 10 frames (in the case where there
%was a jitter in Arduino signal and the camera aquisition, causing
%stimulation to occur up to 10 frames early).
significance = (~isempty(spikeLocs)&&...
    ~isempty(find((spikeLocs(spikeLocs>stimFrame)-stimFrame)<(2*frameRate))))||...
    ~isempty(find(abs((spikeLocs-stimFrame))<=10));

if significance
    %Find frame where transient starts. Begin looking 10 frames prior to
    %stim in order to accomodate Arduino early stim bugs.
    spikeLocsPositive = spikeLocs(spikeLocs>=(stimFrame-10));
    spikeLocsPositive = spikeLocsPositive(spikeLocsPositive<(stimFrame+10));
    if isempty(spikeLocsPositive)
        %If no transient detected, return NaN array for fit and a flat fit
        %curve.
        significance = 0;
        fitResults=[NaN NaN NaN NaN];
        ydata = zeros(1,length(trace(stimFrame:end)));
        xdata = 1:length(ydata);
        xdata = xdata./frameRate;
        shiftedxData = xdata+stimFrame./frameRate;
        fitPlot = [shiftedxData; ydata];
        rootResNorm = NaN;
    else
        %Find the starting frame by finding the max dF/F value within these
        %frames and then go 1s backwards to local minimum.
        [val,idx]=max(trace(spikeLocsPositive));
        fitStartFrame = spikeLocsPositive(idx);
        searchWindow = fitStartFrame-floor(2*frameRate):fitStartFrame;
        [val, idx] = max(diff(trace(searchWindow)));
        fitStartFrame = searchWindow(idx);
        ydata = trace(fitStartFrame:fitStartFrame+floor(10.*frameRate));
        %Fix negative offset if there is one
        negOffset = min(ydata);
        if negOffset<0
            ydata = ydata-negOffset;
        end
        xdata = 0:length(ydata)-1;
        xdata = xdata./frameRate;
        %Fit parameters [A t_on t_off offset]
        x0 = [1, 1, 1, 0]; %pick arbitrary initial values for the constant and tau
        F = @(x,xdata)x(1)*(1-exp(-(xdata)./x(2))).*exp(-(xdata)./x(3))+x(4);
        opts = optimset('Display','off');
        warning off;
        lowerBounds = [0,0,0.01,-1]; %Bounds for fit parameters.
        upperBounds = [5,100,100,1]; %Bounds for fit parameters
        [fitResults,resnorm] = lsqcurvefit(F,x0,xdata,ydata,lowerBounds,upperBounds,opts); %adds the curve fit parameters to the parameter matrix
        rootResNorm = sqrt(resnorm);
        warning on;
        shiftedxData = xdata+(fitStartFrame./frameRate);
        x = shiftedxData;
        y = F(fitResults,xdata);
        %Fix offset if one was made
        if negOffset<0
            y = y+negOffset;
        end
        fitPlot = [x; y];   
    end
else
    %If no transient detected, return NaN array for fit and a flat fit
    %curve.
    fitResults=[NaN NaN NaN NaN];
    ydata = zeros(1,length(trace(stimFrame:end)));
    xdata = 1:length(ydata);
    xdata = xdata./frameRate;
    shiftedxData = xdata+stimFrame./frameRate;
    fitPlot = [shiftedxData; ydata];
    rootResNorm = NaN;
end

end