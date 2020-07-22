function stop_callback(obj,~,~)
    % Run when the stop button is pressed
    % If the system has not been told to stop after the next section, pressing the 
    % button again will stop this from happening. Otherwise we proceed with the 
    % question dialog. Also see SIBT.tileScanAbortedInScanImage

    if obj.verbose, fprintf('In acquisition_view.stop callback\n'), end

    if obj.model.abortAfterSectionComplete
        obj.model.abortAfterSectionComplete=false;
        return
    end

    stopNow='Yes: stop NOW';

    stopAfterSection='Yes: stop after this section';
    noWay= 'No way';
    choice = questdlg('Are you sure you want to stop acquisition?', '', stopNow, stopAfterSection, noWay, noWay);

    switch choice
        case stopNow

            %If the acquisition is paused we un-pause then stop. No need to check if it's paused.
            obj.model.scanner.resumeAcquisition;

            %TODO: these three lines also appear in BT.bake
            obj.model.leaveLaserOn=true; %TODO: we could have a GUI come up that allows the user to choose if they want this happen.
            obj.model.abortAcqNow=true; %Otherwise in ribbon scanning it moved to the next optical plane
            obj.model.scanner.abortScanning;
            obj.model.scanner.disarmScanner;
            obj.model.detachLogObject;
            set(obj.button_Pause, obj.buttonSettings_Pause.disabled{:})

        case stopAfterSection
            %If the acquisition is paused we resume it then it will go on to stop.
            obj.model.scanner.resumeAcquisition;
            obj.model.abortAfterSectionComplete=true;

        otherwise
            %Nothing happens
    end 
end %stop_callback