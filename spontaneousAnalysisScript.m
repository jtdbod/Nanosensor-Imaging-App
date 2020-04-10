% Script for parsing and searching for spontaneous release event from .mat
% files generated using App

numRois = size(results.roiData,2);
numFrames = size(results.roiData(1).dFdetrend,2);

traces = zeros(numRois,numFrames);

for i = 1:numRois
    traces(i,:) = results.roiData(i).dFdetrend;
end

%%
yShift=0;
for i=1:numRois
   
    plot(traces(i,:)...
        +yShift)
    %yShift = max(results.fitData(i).fitPlot(2,:)+yShift);
    yShift = max(traces(i,:)+yShift);
    hold on

end