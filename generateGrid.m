function [roiMask]=generateGrid(app)%Generate grid of ROIs
gridSize=app.imageStackInfo.gridSize;
height = app.imageStackInfo.height;
width = app.imageStackInfo.width;
mask = ones(height,width);
mask(gridSize:gridSize:end,:)=0;
mask(:,gridSize:gridSize:end)=0;
%Number each ROI
cc=bwconncomp(mask);
roiMask = labelmatrix(cc);
%Eliminate the small edge ROIs
roiData = regionprops(roiMask,'Area');
maxRoiArea = max([roiData(:).Area]);
for i = 1:max(roiMask(:))
    if roiData(i).Area < (0.7*maxRoiArea)
        roiMask(roiMask==i)=0;
    end
end
%Renumber the roi mask
cc = bwconncomp(roiMask);
roiMask = labelmatrix(cc);
drawGrid(roiMask,app.UIAxes);
end
