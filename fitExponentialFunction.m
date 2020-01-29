function[fitResults, rootResNorm, fitPlot, spikeLocs, significance]=fitExponentialFunction(trace,stimFrame,frameRate)
% Determine if any transients occur using a simple gradient method and
% assumption of negative gaussian noise. Then, if transients are present,
% fit a multiexponential curve to the data.
% fitResults = [A 1/tau_off 1/tau_on vertical_offset]   

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
significance = ~isempty(spikeLocs)&&~isempty(find(spikeLocs>stimFrame))&&~isempty(find(spikeLocs<stimFrame+floor((2*frameRate))));
if significance
    %Find frame where transient starts
    [val,idx]=min(abs(spikeLocs-stimFrame));
    fitStartFrame = spikeLocs(idx)-1;
    ydata = trace(fitStartFrame:end);
    xdata = 1:length(ydata);
    xdata = xdata./frameRate;
    %Fit parameters [A t_off t_on offset]
    x0 = [max(ydata), 1/5, 1, 0.03]; %pick arbitrary initial values for the constant and tau 
    F = @(x,xdata)x(1).*(1-exp(-x(3)*xdata)).*exp(-x(2).*xdata)+x(4); %defines first order equation
    opts = optimset('Display','off');
    warning off;
    lowerBounds = [0,1/15,1/10,0.0001]; %Bounds for fit parameters.
    upperBounds = [1000,1/0.01,1/0.01,0.05]; %Bounds for fit parameters
    [fitResults,resnorm] = lsqcurvefit(F,x0,xdata,ydata,lowerBounds,upperBounds,opts); %adds the curve fit parameters to the parameter matrix
    rootResNorm = sqrt(resnorm);
    warning on;
    shiftedxData = xdata+fitStartFrame./frameRate;
    fitPlot = [shiftedxData; F(fitResults,xdata)];
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