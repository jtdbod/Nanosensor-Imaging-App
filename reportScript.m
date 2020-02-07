function[] = reportScript(results)
%% Analysis Report Summary

%%
disp(strcat('File Processed: ',...
    results.imageStackInfo.pathName,results.imageStackInfo.fileName));
disp(strcat('Timestamp: ',datestr(datetime)));
disp(strcat('Processed Using Version: ',results.versionNumber));

%%
fitPlots = zeros(size(results.fitData,2),...
    size(results.fitData(1).fitPlot,2));
xfit = results.fitData(1).fitPlot(1,:);
x = (1:length(results.roiData(1).dFdetrend))./results.imageStackInfo.frameRate;
fitResults = zeros(size(results.fitData,2),size(results.fitData(1).fitResults,2));
df = zeros(size(results.roiData(1),2),size(results.roiData(1).dFdetrend,2));
aucs = zeros(1,size(results.roiData,2));
for i = 1:size(results.fitData,2)
    %fitPlots(i,:) = results.fitData(i).fitPlot(2,:);
    fitResults(i,:) = results.fitData(i).fitResults;
    df(i,:) = results.roiData(i).dFdetrend;
    aucs(i) = results.roiData(i).auc;
end
%%
h1=figure();
for i=1:size(results.fitData,2)
    plot(results.fitData(i).fitPlot(1,:),results.fitData(i).fitPlot(2,:))
    hold on
end
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
plotSpread({fitResults(:,2)});
ylabel('\tau_{On} (s)')
subplot(132)
plotSpread({fitResults(:,3)});
ylabel('\tau_{Off} (s)')
subplot(133)
plotSpread({fitResults(:,1)})
ylabel('Multiplicitive Constant (a.u.)')

%%


%%
h3=figure();
hold on
plot(results.fitData(1).fitPlot(1,:),results.fitData(1).fitPlot(2,:));
plot(x,results.roiData(1).dFdetrend);
%yShift = max(results.fitData(1).fitPlot(2,:));
yShift = max(results.roiData(1).dFdetrend);
x = (1:length(results.roiData(1).dFdetrend))./results.imageStackInfo.frameRate;
for i=2:size(results.fitData,2)
    plot(results.fitData(i).fitPlot(1,:),results.fitData(i).fitPlot(2,:)...
        +yShift)
    plot(x,results.roiData(i).dFdetrend+yShift);
    %yShift = max(results.fitData(i).fitPlot(2,:)+yShift);
    yShift = max(results.roiData(i).dFdetrend+yShift);
end
xlabel('Time(s)')
ylabel('dF/F0')
position = get(h3,'Position');
set(gcf,'Position',[position(1) position(2) position(3) 3*position(4)])

%%
close(h1)
close(h1a)
close(h2)
close(h3)

%%

end



