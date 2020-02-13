function[fitResults, rootResNorm, fitPlot, spikeLocs, significance]=fitExponentialFunction(trace,stimFrame,frameRate)
% Determine if any transients occur using a simple gradient method and
% assumption of negative gaussian noise. Then, if transients are present,
% fit a multiexponential curve to the data.
% fitResults = [multiplicative_factor,tau_on,tau_off,offset]  

% Estimate spikes using simple gradient and gaussian noise
spikeLocs = [];
xdata = 1:length(trace);
ydata = trace;
gradTrace = diff(ydata)./diff(xdata);
negValues = gradTrace(gradTrace<0);
noise = [negValues -negValues];
threshold = 3*std(noise);
spikeLocs = find(gradTrace>threshold);%Offset by 1 to account for diff calculation
%Determine if they are distinct spikes or not.
if length(spikeLocs)>1
    reducedSpikeLocs=[];
    flipSpikeLocs = flip(spikeLocs);
    reducedSpikeLocs = flipSpikeLocs(diff(-flipSpikeLocs)>2);
    if isempty(reducedSpikeLocs)
        spikeLocs = spikeLocs(1);
    else
        spikeLocs = [spikeLocs(1) flip(reducedSpikeLocs)];
    end
    %This effectively checks for spikes that are closer than 2 frames apart
    %and then treats that as a single spike occuring
end

%Fit exponential function to trace starting from stimulus if spike occurs
%within 2 seconds of stimulus or within 2 frames (in the case where there
%was a jitter in Arduino signal and the camera aquisition.
significance = (~isempty(spikeLocs)&&...
    ~isempty(find((spikeLocs(spikeLocs>stimFrame)-stimFrame)<(2*frameRate))))||...
    ~isempty(find(abs((spikeLocs-stimFrame))<=2));
if significance
    %Find frame where transient starts
    spikeLocsPositive = spikeLocs(spikeLocs>=(stimFrame-2));
    diffFrame = spikeLocsPositive-stimFrame;
    [val,idx]=min(diffFrame);
    fitStartFrame = spikeLocsPositive(idx);
    %fitStartFrame = stimFrame;
    %ydata = trace(fitStartFrame:fitStartFrame+floor(5.*frameRate));
    ydata = trace(fitStartFrame:fitStartFrame+floor(10.*frameRate));
    %Fix negative offset if there is one
    negOffset = min(ydata);
    if negOffset<0
        ydata = ydata-negOffset;
    end
    xdata = 0:length(ydata)-1;
    xdata = xdata./frameRate;
    %Fit parameters [A t_off t_on offset]
    x0 = [1, 1, 1, 0]; %pick arbitrary initial values for the constant and tau
    F = @(x,xdata)x(1)*(1-exp(-(xdata)./x(2))).*exp(-(xdata)./x(3))+x(4);
    opts = optimset('Display','off');
    warning off;
    lowerBounds = [0,0,0.01,-1]; %Bounds for fit parameters.
    upperBounds = [5,100,100,1]; %Bounds for fit parameters
    [fitResults,resnorm] = lsqcurvefit(F,x0,xdata,ydata,lowerBounds,upperBounds,opts); %adds the curve fit parameters to the parameter matrix
    rootResNorm = sqrt(resnorm);
    warning on;
    shiftedxData = xdata+(fitStartFrame)./frameRate;
    x = shiftedxData;
    y = F(fitResults,xdata);
    %Fix offset if one was made
    if negOffset<0
        y = y+negOffset;
    end
    fitPlot = [x; y];
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