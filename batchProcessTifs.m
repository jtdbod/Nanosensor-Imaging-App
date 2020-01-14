function [] = batchProcessTifs(app)

selpath = uigetdir;
tifFiles = dir(strcat(selpath,'/*.tif'));

for file = 1:size(tifFiles,1)
    FileName = tifFiles(file).name;
    PathName = selpath;
    if FileName==0
        %User cancelled open command. Do nothing.
        error('Cancelled by user or no TIF files found');
    else
        %Load stack
        loadTifStack(app,FileName,PathName);
        fileinfo=imfinfo(strcat(PathName,'/',FileName));
        handles.DataSet.numFrames=size(fileinfo,1);
        
        
        %Generate Mean Projection and dF Max Projecitons and store in handles
        if ~isfield(handles.DataSet.projectionImages,'meanProj')
        currFig = gcf;
        axes(handles.axes1);
        cla(handles.axes1);
        title('Calculating Mean Projection')
        xlabel('')
        imageStack = handles.ImageStack;
        imstack = imageStack;
        if any(imageStack(:)<0)
            imstack = imageStack-min(imageStack(:));
        end

        meanProjImage = mean(imstack,3);
        meanProjImageFilt = medfilt2(meanProjImage,[3 3]);
        handles.DataSet.projectionImages.meanProj = meanProjImageFilt;
        guidata(hObject,handles);
        end

        if ~isfield(handles.DataSet.projectionImages,'dFMaxProj')
        currFig = gcf;
        axes(handles.axes1);
        cla(handles.axes1);
        title('Calculating dF Projection')
        xlabel('')
        imstack = handles.ImageStack;
        dFImage = imstack-handles.DataSet.projectionImages.meanProj;
        maxdFProjImage = max(dFImage,[],3);
        maxdFProjImageFilt = medfilt2(maxdFProjImage,[4 4]);
        handles.DataSet.projectionImages.dFMaxProj = maxdFProjImageFilt;
        guidata(hObject,handles);
        end
        clear imstack dFImage
        guidata(hObject,handles);%To save DataSet to handles

        %Display first frame after file loads.
        axes(handles.axes1);
        cla(handles.axes1);
        colormap(defineGemColormap);
        imagesc(imageStack(:,:,1));
        title('Frame 1')
        cla(handles.axes2);
        cla(handles.axes3);

        delete(barhandle);
        guidata(hObject,handles);%To save DataSet to handles

    end


    %handles = generateRois(handles);
    handles = generateGrid(handles);
    guidata(hObject,handles);
    handles = processTifFile(handles);
    guidata(hObject,handles);
    handles = calculateDecayConstant(handles);
    guidata(hObject,handles);
end

end
