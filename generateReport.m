function[] = generateReport(app)

results = app.results;
%%%%
disp(strcat('File Processed: ',...
    results.imageStackInfo.pathName,results.imageStackInfo.fileName));
disp(strcat('Timestamp: ',datestr(datetime)));
disp(strcat('Processed Using Version: ',results.versionNumber));

yfitPlots = [];
xfitPlots = [];
x = (1:length(results.roiData(1).dFdetrend))./results.imageStackInfo.frameRate;
fitResults = [];
df = [];
aucs = [];
idx=1;
for i = 1:size(results.fitData,2)
    if results.fitData(i).significance
        yfitPlots(idx,:) = results.fitData(i).fitPlot(2,:);
        xfitPlots(idx,:) = results.fitData(i).fitPlot(1,:);
        fitResults(idx,:) = results.fitData(i).fitResults;
        df(idx,:) = results.roiData(i).dFdetrend;
        aucs(idx) = results.roiData(i).auc;
        idx=idx+1;
    end
end
%%%%
h1=figure();
sgtitle({strcat('File Processed: ',...
    results.imageStackInfo.pathName,results.imageStackInfo.fileName),...
    strcat('Timestamp: ',datestr(datetime),...
    '--Processed Using Version: ',results.versionNumber)},'Interpreter','none');

subplot(3,6,[1:3])
for i=1:size(df,1)
    plot(x,df(i,:))
    hold on
end
xlabel('Time (s)')
ylabel('dF/F0')
title('Baseline Corrected')

%%%%
subplot(3,6,[7:9])
for i=1:size(yfitPlots,1)
    plot(xfitPlots(i,:),yfitPlots(i,:))
    hold on
end
xlabel('Time (s)')
ylabel('dF/F0')
title('Exponential Fits')

%%%%
subplot(3,6,13)
plotSpread({fitResults(:,2)});
ylabel('\tau_{On} (s)')
subplot(3,6,14)
plotSpread({fitResults(:,3)});
ylabel('\tau_{Off} (s)')
subplot(3,6,15)
plotSpread({fitResults(:,1)})
ylabel('Multiplicitive Constant (a.u.)')

%%%%
subplot(3,6,[4:6,10:12])
hold on
plot(results.fitData(1).fitPlot(1,:),results.fitData(1).fitPlot(2,:));
plot(x,results.roiData(1).dFdetrend);
%yShift = max(results.fitData(1).fitPlot(2,:));
yShift = max(results.roiData(1).dFdetrend);
x = (1:length(results.roiData(1).dFdetrend))./results.imageStackInfo.frameRate;
for i=2:size(results.fitData,2)
    if results.fitData(i).significance
        plot(results.fitData(i).fitPlot(1,:),results.fitData(i).fitPlot(2,:)...
            +yShift)
        plot(x,results.roiData(i).dFdetrend+yShift);
        %yShift = max(results.fitData(i).fitPlot(2,:)+yShift);
        yShift = max(results.roiData(i).dFdetrend+yShift);
    end
end
xlabel('Time(s)')
ylabel('dF/F0')
%position = get(h3,'Position');
%set(gcf,'Position',[position(1) position(2) position(3) 3*position(4)])

%%%%
subplot(3,6,16:18)
mask = results.roiMask;
image = results.imageStackInfo.firstFrame;

stimFrame = results.imageStackInfo.stimFrame;
frameRate = results.imageStackInfo.frameRate;
for i =1:max(mask(:))
    maxdf(i)=max(results.roiData(i).dFdetrend(:,stimFrame:stimFrame+floor(3*frameRate)),[],2);
end
normdf = maxdf-min(maxdf)+0.01*min(maxdf);
normdf = normdf./max(normdf);
normdf = ceil(256*normdf);

imagesc(image)
hold on

cmap = colormap('hot');
colormap('parula');
%colormap('parula');
for i = 1:max(mask(:))
    position = [floor(results.roiData(i).CenterX(1)),...
    floor(results.roiData(i).CenterY(1)),...
    results.imageStackInfo.gridSize-2,...
    results.imageStackInfo.gridSize-2];
    if normdf(i)==0
        normdf(i)=.001; %Fix index = 0 error.
    end
    rectangle('Position',position,'Curvature',0.5,'EdgeColor',[cmap(normdf(i),:),0.5],'LineWidth',4);
end
caxis;

%%%%
saveas(h1,strcat(results.imageStackInfo.pathName,'/',results.imageStackInfo.fileName(1:end-3),'.fig'))
close(h1)

end