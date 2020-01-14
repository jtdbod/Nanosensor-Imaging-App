function []=drawGrid(roiMask,axesSelection)
hold(axesSelection,'on')
roi_list = nonzeros(unique(roiMask));
mask = roiMask;
cidx = 0;
for roi_index=1:length(roi_list)
    roi = roi_list(roi_index);
    roi_mask = mask;
    roi_mask(find(roi_mask~=roi))=0;
    [B,L,N,A] = bwboundaries(roi_mask,'noholes');
    colors=['b' 'g' 'r' 'c' 'm' 'y'];
    cidx = mod(cidx,length(colors))+1; %Cycle through colors for drawing borders
    for k=1:length(B),
        boundary = B{k};
        %cidx = mod(k,length(colors))+1;
        plot(axesSelection,boundary(:,2), boundary(:,1),...
           colors(cidx),'LineWidth',1);
        %randomize text position for better visibility
        %rndRow = ceil(length(boundary)/(mod(k,7)+1));
        rndRow = 1;
        col = boundary(rndRow,2); row = boundary(rndRow,1);
        %h = text(col+1, row-1, num2str(L(row,col)));
        %h = text(col+1, row-1, num2str(roi));
        %text(axesSelection,col+length(boundary)/8, row+length(boundary)/8, num2str(roi));
        s=regionprops(L,'Centroid');
        text(axesSelection,s.Centroid(1),s.Centroid(2),num2str(roi),'HorizontalAlignment','Center');
        %set(axesSelection,'Color',colors(cidx),'FontSize',14);
    end
end
hold(axesSelection,'off')
end
