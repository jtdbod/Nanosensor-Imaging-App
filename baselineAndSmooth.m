data=DataSet.measuredValues(1).MeanIntensity;

%%
frameRate = 8.33;
window = 25*frameRate; %Use a 25 second smoothing window;
filtdata = medfilt1(data,301,'truncate');
baselinedData = data-filtdata;

smoothdata = sgolayfilt(baselinedData,3,25);

subplot(121)
plot(data)
hold on
subplot(122)
plot(filtdata)


%%
for i = 1:size(DataSet.measuredValues,2)
    data=DataSet.measuredValues(i).MeanIntensity;
    %smoothdata = sgolayfilt(data,3,25);
    smoothdata = data;
    frameRate = 8.33;
    window = 2*(floor((35*frameRate)/2))+1; %Use a 35 second smoothing window, ensuring it is odd number;
    filtdata = medfilt1(smoothdata,window,'truncate');
    baselinedData = smoothdata-filtdata;
    noise = std(data(1:190));
    zscore = baselinedData./noise;
    %smoothdata = smoothdata+min(smoothdata);
    f0=mean(smoothdata(1:190));
    df1 = (smoothdata-f0)./f0;
    df2 = (smoothdata-filtdata)./filtdata;
    figure(1)
    subplot(411)
    plot(df1);
    hold on
    ylabel('dF/F')
    title('F0 calculated using mean of first 200 frames')
    subplot(412)
    plot(df2)
    title('F0 calculated using moving F0 estimate')
    ylabel('dF/F')
    hold on
    subplot(413)
    plot(data-mean(data))
    hold on
    subplot(414)
    plot(zscore);
    hold on
end



%%
firstFrame = imageStack(:,:,1);

reshapedData = zeros(size(imageStack,3),length(firstFrame(:)));

for i=1:size(imageStack,3)
image=imageStack(:,:,i);
data = reshape(image,[],1);
reshapedData(i,:)=data;
end

%% Testing if this is fast enough to do on pixel by pixel basis
traces = zeros(size(reshapedData,2),size(reshapedData,1));
for i = 1:size(reshapedData,2)
    round(100*(i/size(reshapedData,2)))
    data=reshapedData(:,i);
    smoothdata = sgolayfilt(data,3,25);
    frameRate = 8.33;
    window = 25*frameRate; %Use a 25 second smoothing window;
    filtdata = medfilt1(smoothdata,301,'truncate');
    baselinedData = smoothdata-filtdata;

    noise = std(data(1:190));
    zscore = baselinedData./noise;
    %smoothdata = smoothdata+min(smoothdata);
    f0=mean(smoothdata(1:190));
    df1 = (smoothdata-f0)./f0;
    df2 = (smoothdata-filtdata)./filtdata;
    traces(i,:)=df;
end

%%

