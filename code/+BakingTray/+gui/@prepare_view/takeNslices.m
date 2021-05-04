function takeNslices(obj,~,~)
    % Take a number of slices off the block 
    %
    % function takeNslices(obj,~,~)
    %
    % Reads from the number of slices edit box and takes this many slices off the block
    % Updates GUI elements accordingly.

    [cuttingPossible,msg]=obj.model.checkIfCuttingIsPossible;
    if ~cuttingPossible
        warndlg(msg,'')
        return
    end

    % Move to the cutting start point. This causes the blade to always
    % return to this position when trimming and it avoids user confusion
    % in cases such as an abort of the cutting that then leads to the blade
    % returning to a location above the sample
    obj.model.moveXYto(obj.model.recipe.CuttingStartPoint.X,0,true)

    %Takes multiple slices according to what is entered in the multiple slice text entry box
    slicesToTake = str2double(obj.editBox.takeNslices.String);
    origString=obj.takeNSlices_button.String;
    obj.takeNSlices_button.ForegroundColor='r';

    for ii=1:slicesToTake
        if ~obj.model.checkIfCuttingIsPossible
            %If the user breaks off the previous section with the blade beyond the cutting start point
            %then no further sections will be cut. However, cutting will restart if the user happened to
            %to abort cutting during the return of the sample to the start point. 
            break
        end
        fprintf('\nCutting slice %d/%d\n',ii,slicesToTake);
        obj.takeNSlices_button.String=sprintf('Slicing %d/%d',ii,slicesToTake);
        success = obj.model.sliceSample(obj.lastSliceThickness, obj.lastCuttingSpeed);

        % Bail out of the loop if the user has stopped the cutting sequence
        if ~success
            break
        end

        pause(2) %so the bath does not swill around too much
    end % for 

    obj.takeNSlices_button.String=origString;
    obj.takeNSlices_button.ForegroundColor='k';
end
