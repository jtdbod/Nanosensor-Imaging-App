function results = loadTifStack(varargin)
    %[file,path] = uigetfile('*.tif');
    if nargin == 1
        app = varargin{1};
        [file,path] = uigetfile('*.tif');
        app.imageStackInfo.fileName = file;
        app.imageStackInfo.pathName = path;
    else
        app = varargin{1};
        file = varargin{2};
        path = varargin{3};
    end
    
    file = strcat(path,'/',file);
    fileinfo = imfinfo(file);
    app.imageStackInfo.height=fileinfo(1).Height;
    app.imageStackInfo.width=fileinfo(1).Width;
    app.imageStackInfo.numFrames=size(fileinfo,1);
    imageStack=zeros(app.imageStackInfo.height,...
        app.imageStackInfo.width,app.imageStackInfo.numFrames);
    %Make progress bar
    f = app.NanosensorImagingAppUIFigure;
    d = uiprogressdlg(f,'Title','Loading Image Stack',...
    'Message','Please Wait','Cancelable','on');
    for j=1:app.imageStackInfo.numFrames
        if d.CancelRequested
            break
        end
        imageStack(:,:,j)=imread(file,j);
        d.Value = j./app.imageStackInfo.numFrames;
    end
    imagesc(app.UIAxes,imageStack(:,:,1));
    app.imageStack = imageStack;
    axis(app.UIAxes,'tight');
    %Convert axes to microns
    pixelConversion = 1/app.PixelsmEditField.Value; %Convert pixels->microns 3.67 pix/um for 60X on Linda's rig
    width = app.imageStackInfo.width*pixelConversion;
    height = app.imageStackInfo.height*pixelConversion;
    tickInterval=10/pixelConversion;
    xticks(app.UIAxes,tickInterval:tickInterval:width/pixelConversion);
    labels = (tickInterval:tickInterval:width/pixelConversion)*pixelConversion;
    xticklabels(app.UIAxes,labels);
    yticks(app.UIAxes,tickInterval:tickInterval:height/pixelConversion);
    labels = (tickInterval:tickInterval:height/pixelConversion)*pixelConversion;
    yticklabels(app.UIAxes,labels);
    set(app.UIAxes,'XAxisLocation','top')
end