function placeNewTilesInPreviewData(obj,~,~)
    % Place new tiles into the preview image 
    %
    %  function placeNewTilesInPreviewData(obj,~,~)
    %
    % Purpose
    % This callback places newly acquired tiles into the preview image of the 
    % BakingTray GUI. This method uses the property "previewTilePositions" to
    % determine where to place the tiles and locates at those positions in the
    % array which houses the preview section image data. This array can be 
    % found: acquisition_view.lastPreviewImageStack array.
    % This callback is run when the tile position increments so that it only
    % runs once per X/Y position.


    if obj.processLastFrames==false || obj.acquisitionInProgress == false
        return
    end

    if obj.lastTilePos.X>0 && obj.lastTilePos.Y>0
        % Caution changing these lines: tiles may be rectangular
        % Tiles are placed based upon the array "previewTilePositions" which is generated by BT.initialisePreviewImageData
        x = (1:size(obj.downSampledTileBuffer,1)) + obj.previewTilePositions(obj.lastTileIndex,2);
        y = (1:size(obj.downSampledTileBuffer,2)) + obj.previewTilePositions(obj.lastTileIndex,1);

        allOK=true;
        if any(x<1)
            fprintf('placeNewTilesInPreviewData has x positions less than 1: not placing tile\n');
            allOK=false;
        end
        if any(y<1)
            fprintf('placeNewTilesInPreviewData has y positions less than 1: not placing tile\n');
            allOK=false;
        end
        if allOK
            %Place the tiles into the full image grid so it can be plotted (there is a listener on this property to update the plot)
            obj.lastPreviewImageStack(y,x,:,:) = obj.downSampledTileBuffer;
        end


        obj.downSampledTileBuffer(:) = 0; %wipe the buffer 

     end % obj.lastTilePos.X>0 && obj.lastTilePos.Y>0

   
end %placeNewTilesInPreviewData