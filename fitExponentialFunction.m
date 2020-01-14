function[fitResults, fitPlot, spikeLocs, significance]=fitExponentialFunction(trace,stimFrame,frameRate)
% Determine if any transients occur using a simple gradient method and
% assumption of negative gaussian noise. Then, if transients are present,
% fit a multiexponential curve to the data.

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
%within 2 seconds of stimulus
significance = ~isempty(spikeLocs)&&~isempty(find(spikeLocs>stimFrame))&&~isempty(find(spikeLocs<stimFrame+(2*frameRate)));
if significance
    ydata = trace(stimFrame:end);
    xdata = 1:length(ydata);
    xdata = xdata./frameRate;
    x0 = [max(ydata), 1/10, 1, 0.03]; %pick arbitrary initial values for the constant and tau 
    F = @(x,xdata)x(1).*(1-exp(-x(3)*xdata)).*exp(-x(2).*xdata)+x(4); %defines first order equation
    opts = optimset('Display','off');
    warning off;
    fitResults = lsqcurvefit(F,x0,xdata,ydata,[],[],opts); %adds the curve fit parameters to the parameter matrix
    warning on;
    shiftedxData = xdata+stimFrame./frameRate;
    fitPlot = [shiftedxData; F(fitResults,xdata)];
else
    fitResults=[];
    fitPlot=[];
end
end