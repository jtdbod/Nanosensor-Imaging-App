%% Analysis Report Summary

%%
disp(strcat('File Processed: ',...
    results.imageStackInfo.pathName,results.imageStackInfo.fileName));
disp(strcat('Timestamp: ',datestr(datetime)));

%%
fitPlots = zeros(size(results.fitData,2),...
    size(results.fitData(1).fitPlot,2));
xfit = results.fitData(1).fitPlot(1,:);
x = (1:length(results.roiData(1).dFdetrend))./results.imageStackInfo.frameRate;
fitResults = zeros(size(results.fitData,2),4);
df = zeros(size(results.roiData(1),2),size(results.roiData(1).dFdetrend,2));
aucs = zeros(1,size(results.roiData,2));
for i = 1:size(results.fitData,2)
    fitPlots(i,:) = results.fitData(i).fitPlot(2,:);
    fitResults(i,:) = results.fitData(i).fitResults;
    df(i,:) = results.roiData(i).dFdetrend;
    aucs(i) = results.roiData(i).auc;
end
%%
h1=figure();
plot(xfit,fitPlots')
xlabel('Time (s)')
ylabel('dF/F0')
title('Exponential Fits')
h1a = figure();
plot(x,df');
xlabel('Time(s)')
ylabel('dF/F0')

%%
h2=figure();
subplot(131)
plotSpread({1./fitResults(:,3)});
ylabel('\tau_{on} (s)')
subplot(132)
plotSpread({1./fitResults(:,2)});
ylabel('\tau_{off} (s)')
subplot(133)
plotSpread({aucs})
ylabel('Area Under Curve of dF/F')

%%

stackedPlots = zeros([size(df)]);
stackedPlots(1,:) = df(1,:);
stackedFits = zeros([size(fitPlots)]);
stackedFits(1,:) = fitPlots(1,:);
for i=2:size(fitPlots,1)
    stackedFits(i,:) = fitPlots(i,:)+max(stackedFits(i-1,:))+0.1*max(fitPlots(1,:));
    stackedPlots(i,:) = df(i,:)+max(stackedFits(i-1,:))+0.1*max(fitPlots(1,:));
end
%%
h3=figure();
plot(xfit,stackedFits')
hold on
plot(x,stackedPlots')
xlabel('Time(s)')
ylabel('dF/F0')
position = get(h3,'Position');
set(gcf,'Position',[position(1) position(2) position(3) 3*position(4)])

%%
close(h1)
close(h1a)
close(h2)
close(h3)


    



