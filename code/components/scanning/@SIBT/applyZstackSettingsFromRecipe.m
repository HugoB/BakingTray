function applyZstackSettingsFromRecipe(obj)
    % applyZstackSettingsFromRecipe
    % This method is (at least for now) specific to ScanImage. 
    % Its main purpose is to set the number of planes and distance between planes.
    % It also sets the the view style to tiled. This method is called by armScanner
    % but also by external classes at certain times in order to set up the correct 
    % Z settings in ScanImage so the user can do a quick Grab and check the
    % illumination correction with depth.


    thisRecipe = obj.parent.recipe;
    if thisRecipe.mosaic.numOpticalPlanes>1
        fprintf('Setting up z-scanning with "step" waveform\n')

        % Only change settings that need changing, otherwise it's slow.
        % The following settings are fixed: they will never change
        if ~strcmp(obj.hC.(obj.fastZsettingLocation).(obj.fastZwaveformLocation),'step') 
            obj.hC.(obj.fastZsettingLocation).(obj.fastZwaveformLocation) = 'step'; %Always
        end

        % Confirm that worked
        if ~strcmp(obj.hC.(obj.fastZsettingLocation).(obj.fastZwaveformLocation),'step') 
        	fprintf('\n\n WARNING: fast z waveform type failed to set to "step". Is set to "%s".\n\n',...
        		obj.hC.(obj.fastZsettingLocation).(obj.fastZwaveformLocation))
        end

        if obj.hC.(obj.fastZsettingLocation).numVolumes ~= 1
            obj.hC.(obj.fastZsettingLocation).numVolumes=1; %Always
        end

        if obj.versionGreaterThan('5.6.1')
            if obj.hC.hStackManager.enable ~=1
                obj.hC.hStackManager.enable=1;
            end
            if ~strcmp(obj.hC.hStackManager.stackMode,'fast')
                obj.hC.hStackManager.stackMode='fast';
            end
        else
            %For Scanimage <= v 5.6.1 we just do this    
            if obj.hC.hFastZ.enable ~=1
                obj.hC.hFastZ.enable=1;
            end
        end

        if obj.hC.hStackManager.stackReturnHome ~= 1
            obj.hC.hStackManager.stackReturnHome = 1;
        end

        % Now set the number of slices and the distance in z over which to image
        sliceThicknessInUM = thisRecipe.mosaic.sliceThickness*1E3;


        if obj.hC.hStackManager.numSlices ~= thisRecipe.mosaic.numOpticalPlanes
            obj.hC.hStackManager.numSlices = thisRecipe.mosaic.numOpticalPlanes + thisRecipe.mosaic.numOverlapZPlanes;
        end

        targetStepSize = round(sliceThicknessInUM/thisRecipe.mosaic.numOpticalPlanes,1);
        if obj.hC.hStackManager.stackZStepSize ~= targetStepSize
            obj.hC.hStackManager.stackZStepSize = targetStepSize;
        end


        if strcmp(obj.hC.hDisplay.volumeDisplayStyle,'3D')
            fprintf('Setting volume display style from 3D to Tiled\n')
            obj.hC.hDisplay.volumeDisplayStyle='Tiled';
        end

    else % There is no z-stack being performed

        %Ensure we disable z-scanning if this is not being used
        obj.hC.hStackManager.numSlices = 1;
        obj.hC.hStackManager.stackZStepSize = 0;
        
        
        if obj.versionGreaterThan('5.6.1')
            if obj.hC.hStackManager.enable ~= 0
                obj.hC.hStackManager.enable=0;
            end
        else
            %For Scanimage <= v 5.6.1 we just do this    
            if obj.hC.hFastZ.enable ~=0
                obj.hC.hFastZ.enable=0;
            end
        end
        
    end


    % Apply averaging as needed
    aveFrames = obj.hC.hDisplay.displayRollingAverageFactor;  
    if aveFrames>1
        fprintf('Setting up averaging of %d frames\n', aveFrames)
    end
    obj.hC.hScan2D.logAverageFactor = 1; % To avoid warning
    obj.hC.hStackManager.framesPerSlice = aveFrames;
    if obj.averageSavedFrames
        obj.hC.hScan2D.logAverageFactor = aveFrames;
    else
        obj.hC.hScan2D.logAverageFactor = 1;
    end

end % applyZstackSettingsFromRecipe
