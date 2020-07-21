classdef chameleonMPX < laser & loghandler
%%  chameleon MPX - control class for Coherent Chameleon synchronously pumped OPO
%
% Example
% C = chameleonMPX('COM1');
%
% Laser control component for Chameleon MPX OPO from Coherent. 
%
% For docs, please see the laser abstract class. 
%
%
% Hugo Blanc - Palaiseau 2020
    methods

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        %constructor
        function obj = chameleonMPX(serialComms,logObject)
        % function obj = chameleon(serialComms,logObject)

            if nargin<1
                error('chameleon MPX requires at least one input argument: you must supply the laser COM port as a string')
            end

            %Attach log object if it is supplied
            if nargin>1
                obj.attachLogObject(logObject);
            end

            obj.maxWavelength=1600;
            obj.minWavelength=1000;
            obj.friendlyName = 'Chameleon MPX';

            fprintf('\nSetting up Chameleon MPX communication on serial port %s\n', serialComms);
            BakingTray.utils.clearSerial(serialComms)
            obj.controllerID=serialComms;
            success = obj.connect;

            if ~success
                fprintf('Component chameleonMPX failed to connect to laser over the serial port.\n')
                return
                %TODO: is it possible to delete it here?
            end

            %Set the target wavelength to equal the current wavelength
            obj.targetWavelength=obj.currentWavelength;

            %Report connection
            fprintf('Connected to Chameleon MPX on serial port %s\n\n', serialComms)

        end %constructor


        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        %destructor
        function delete(obj)
            fprintf('Disconnecting from Chameleon MPX\n')
            if ~isempty(obj.hC) && isa(obj.hC,'serial') && isvalid(obj.hC)
                fprintf('Closing serial communications with Chameleon MPX\n')
                flushinput(obj.hC) %There may be characters left in the buffer because of the timers used to poll the laser
                fclose(obj.hC);
                delete(obj.hC);
            end  
        end %destructor


        function success = connect(obj)
            obj.hC=serial(obj.controllerID,'BaudRate',38400, ...
                        'Terminator', 'LF');
            
            try 
                fopen(obj.hC); %TODO: could test the output to determine if the port was opened
            catch ME
                fprintf(' * ERROR: Failed to connect to Chameleon MPX:\n%s\n\n', ME.message)
                success=false;
                return
            end

            flushinput(obj.hC) % Just in case
            success = false;
            if ~isempty(obj.hC)
                
                    %double-check we can talk to the OPO
                    [~,s] = obj.isShutterOpen;
                    if s==true
                        success=true;
                    else
                        fprintf('Failed to communicate with Chameleon MPX\n')
                        success=false;
                    end
                    
            end 
            obj.isLaserConnected=success;
        end %connect


        function success = isControllerConnected(obj)
%             if strcmp(obj.hC.Status,'closed')
%                 success=false;
%             else
%                 [~,success] = obj.isShutterOpen;
%             end
%             obj.isLaserConnected=success;
%         end
               success=true;
            obj.isLaserConnected=success;
        end


        function success = turnOn(obj)
            success=true;
            obj.isLaserModeLocked=true;
            obj.isLaserOn=true;
        end


        function success = turnOff(obj)
            success=true;
            obj.isLaserModeLocked=false;
            obj.isLaserOn=false;
        end

        function powerOnState = isPoweredOn(obj)
            powerOnState=obj.isLaserOn;
        end


        function [laserReady,msg] = isReady(obj)
%             [success,reply]=obj.sendAndReceiveSerial('STATUS?');
%             if ~success
%                 reply=nan;
%                 return
%             end
%             if reply=="OK"
%                 msg='laser Chameleon MPX is ready';
%                 laserReady=true;
%                 obj.isLaserReady=true;
%             else
%                 msg=sprintf('laser Chameleon MPX status : %s', reply);
%                 laserReady=false;
%                 obj.isLaserReady=false;
%             end
            msg='laser Chameleon MPX is ready';
            laserReady=true;
            obj.isLaserReady=true;
        end


        function modelockState = isModeLocked(obj)
%             [success,reply]=obj.sendAndReceiveSerial('?MDLK');
%             if ~success %If we can't talk to it, we assume it's also not modelocked (maybe questionable, but let's go with this for now)
%                 modelockState=false;
%                 obj.isLaserModeLocked=modelock;
%                 return
%             end
% 
%             % Determine modelock state
%             modelockState = str2double(reply);
%             modelockState = (modelockState==1); %Because it can equal 2 (CW) or 0 (Off)
%             obj.isLaserModeLocked=modelockState;
%         end
                    modelockState=obj.isLaserModeLocked;
        end


        function success = openShutter(obj)
            success1=obj.sendAndReceiveSerial('PUMP OUT SHUTTER=1',false);
            pause(0.75) %Because it takes the laser about a second to register the change
            success2=obj.sendAndReceiveSerial('OPO OUT SHUTTER=1',false);
            pause(0.75) %Because it takes the laser about a second to register the change
            success=success1 && success2;
            if success
                obj.isLaserShutterOpen=true;
            end
        end
        
        function success = openPumpOutShutter(obj)
            success=obj.sendAndReceiveSerial('PUMP OUT SHUTTER=1',false);
            pause(0.75) %Because it takes the laser about a second to register the change
        end
        
        function success = openOpoOutShutter(obj)
            success=obj.sendAndReceiveSerial('OPO OUT SHUTTER=1',false);
            pause(0.75) %Because it takes the laser about a second to register the change
        end


        function success = closeShutter(obj)
            success1=obj.sendAndReceiveSerial('PUMP OUT SHUTTER=0',false);
            pause(0.75) %Because it takes the laser about a second to register the change
            success2=obj.sendAndReceiveSerial('OPO OUT SHUTTER=0',false);
            pause(0.75) %Because it takes the laser about a second to register the change
            success=success1 && success2;
            if success
                obj.isLaserShutterOpen=false;
            end
        end
        
        function success = closePumpOutShutter(obj)
            success=obj.sendAndReceiveSerial('PUMP OUT SHUTTER=0',false);
            pause(0.75) %Because it takes the laser about a second to register the change
        end
        
        function success = closeOpoOutShutter(obj)
            success=obj.sendAndReceiveSerial('OPO OUT SHUTTER=0',false);
            pause(0.75) %Because it takes the laser about a second to register the change
        end


        function [shutterState,success] = isShutterOpen(obj)
            [success1,reply1]=obj.sendAndReceiveSerial('PUMP OUT SHUTTER?');
            [success2,reply2]=obj.sendAndReceiveSerial('OPO OUT SHUTTER?');
            success=success1 & success2;
            if ~success
                shutterState=[];
                return
            end
            if reply1=='1' && reply2=='1'
                reply=1;
            else
                reply=0;
            end
            shutterState = reply; %if open the command returns 1
            obj.isLaserShutterOpen=shutterState;
        end
        
        function [shutterState,success] = isPumpOutShutterOpen(obj)
            [success,reply]=obj.sendAndReceiveSerial('PUMP OUT SHUTTER?');
            if ~success
                shutterState=[];
                return
            end
            shutterState = str2double(reply); %if open the command returns 1
            obj.isLaserShutterOpen=shutterState;
        end
        
        function [shutterState,success] = isOpoOutShutterOpen(obj)
            [success,reply]=obj.sendAndReceiveSerial('OPO OUT SHUTTER?');
            if ~success
                shutterState=[];
                return
            end
            shutterState = str2double(reply); %if open the command returns 1
            obj.isLaserShutterOpen=shutterState;
        end

        function wavelength = readWavelength(obj) 
            [success,wavelength]=obj.sendAndReceiveSerial('OPO WAVELENGTH?'); 
            if ~success
                wavelength=[];
                return
            end
            wavelength = str2double(wavelength)*0.1;
            if ~isnan(wavelength)
                obj.currentWavelength=wavelength;
            else
                fprintf('Failed to read OPO wavelength from Chameleon MPX. Likely laser is tuning.\n')
            end
        end

%         function Pumpwavelength = readPumpWavelength(obj) 
%             [success,Pumpwavelength]=obj.sendAndReceiveSerial('PUMP WAVELENGTH?'); 
%             if ~success
%                 Pumpwavelength=[];
%                 return
%             end
%             Pumpwavelength = str2double(Pumpwavelength*0.1);
%             if ~isnan(Pumpwavelength)
%                 obj.currentOPOWavelength=Pumpwavelength;
%             else
%                 fprintf('Failed to read pump wavelength from Chameleon OPO. Likely laser is tuning.\n')
%             end
%         end
        
        function success = setWavelength(obj,wavelengthInNM)

            success=false;
            if length(wavelengthInNM)>1
                fprintf('wavelength should be a scalar')
                return
            end
            if ~obj.isTargetWavelengthInRange(wavelengthInNM)
                return
            end
            wavelengthInAngstrom=10*wavelengthInNM;
            cmd = sprintf('OPO WAVELENGTH=%d', round(wavelengthInAngstrom));
            [success,wavelength]=obj.sendAndReceiveSerial(cmd,false);
            if ~success
                return
            end
            obj.currentWavelength=wavelength;
            obj.targetWavelength=wavelengthInNM;

        end
        
        function tuning = isTuning(obj) % useless 

            lA = obj.readWavelength;
            pause(0.23)
            lB = obj.readWavelength;

            if lA == lB
                tuning=false;
            else
                tuning=true;
            end
        end

        function Status = readStatus(obj)
            [success,reply]=obj.sendAndReceiveSerial('STATUS?');
            if ~success
                Status=nan;
                return
            end
            Status=reply;    
            
        end


        function laserPower = readPower(obj)
            [success,laserPower]=obj.sendAndReceiveSerial('OPO POWER?');
            if ~success
                laserPower=[];
                return
            end
            laserPower = str2double(laserPower);
        end


        function laserID = readLaserID(obj)
            [success,laserID]=obj.sendAndReceiveSerial('*IDN?');
            if ~success
                laserID=[];
                return
            end
            laserID = ['Chameleon MPX, Version, Serial Number, Device Type: ', laserID];
        end


        function laserStats = returnLaserStats(obj)
%             lambda = obj.readWavelength;
%             outputPower = obj.readPower;
%             humidity = obj.readHumidity;
% 
%             laserStats=sprintf('wavelength=%dnm,outputPower=%dmW,humidity=%0.1f', ...
%                 lambda,outputPower,humidity);
            [success,reply]=obj.sendAndReceiveSerial('PARAMETER?');
            if ~success
                laserStats=[];
                return
            end
            laserStats = reply;
        end
        
        function success=setWatchDogTimer(obj,value)
%             if value <= 0
%                 [success,~] = obj.sendAndReceiveSerial('HB=0');
%                 return
%             else
%                 [success,~] = obj.sendAndReceiveSerial('HB=1');
%                 if ~success
%                     return
%                 end
%                 if value>100
%                     value=100;
%                 elseif value<1
%                     value=1;
%                 end
%                 value = num2str(round(value));
%                 [success,~] = obj.sendAndReceiveSerial(['HBR=',value]);
%             end 
            success=true;
        end

        
        % Chameleon MPX specific
        function laserHumidity = readHumidity(obj)
            % I think some lasers don't have sensor and just return 0
            [success,laserHumidity]=obj.sendAndReceiveSerial('HUMIDITY?');
            if ~success
                laserHumidity=[];
                return
            end
            laserHumidity = str2double(laserHumidity);
        end
        
        function laserTemperature = readTemperature(obj)
            % I think some lasers don't have sensor and just return 0
            [success,laserTemperature]=obj.sendAndReceiveSerial('TEMPERATURE?');
            if ~success
                laserTemperature=[];
                return
            end
            laserTemperature = str2double(laserTemperature);
        end


        function warmedUpValue = readWarmedUp(obj)
%             % Return a bool that defines whether the laser is warmed up and
%             % ready emit. To determin this we querthe operating status
%             % text which returns "Starting" or "OK"
%             [success,warmedUpValue]=obj.sendAndReceiveSerial('?ST');
%             if ~success
%                 warmedUpValue=[];
%                 return
%             end
%             
%             if strfind(warmedUpValue,'OK')
%                 warmedUpValue=true;
%             else
%                 warmedUpValue=false;
%             end
            warmedUpValue=true;
        end

        
        function keyState = readKeySwitch(obj)
%             % Is the key set to enable or disable?
%             [success,reply] = obj.sendAndReceiveSerial('?K');
%             if ~success
%                 keyState=[];
%                 return
%             end
%             keyState = str2double(reply);
            keyState=1;
        end

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        function [success,reply]=sendAndReceiveSerial(obj,commandString,waitForReply)
            % Send a serial command and optionally read back the reply
            if nargin<3
                waitForReply=true;
            end

            if isempty(commandString) || ~ischar(commandString)
                reply='';
                success=false;
                obj.logMessage(inputname(1),dbstack,6,'chameleonOPO.sendReceiveSerial command string not valid.')
                return
            end

            fprintf(obj.hC,commandString);

            if ~waitForReply
                reply=[];
                success=true;
                if obj.hC.BytesAvailable>0
                    fprintf('Not waiting for reply by there are %d BytesAvailable\n',obj.hC.BytesAvailable)
                end
                return
            end

            reply=fgets(obj.hC);
            doFlush=1; %TODO: not clear right now if flushing the buffer is even the correct thing to do. 
            if obj.hC.BytesAvailable>0
                if doFlush
                    fprintf('Read in from the Chameleon buffer using command "%s" but there are still %d BytesAvailable. Flushing.\n', ...
                        commandString, obj.hC.BytesAvailable)
                    flushinput(obj.hC)
                else
                    fprintf('Read in from the Chameleon buffer using command "%s" but there are still %d BytesAvailable. NOT FLUSHING.\n', ...
                        commandString, obj.hC.BytesAvailable)
                end
            end

            if ~isempty(reply)
                reply(end)=[];
            else
                msg=sprintf('Laser serial command %s did not return a reply\n',commandString);
                success=false;
                obj.logMessage(inputname(1),dbstack,6,msg)
                return
            end
            
            % If the laser is echoing back the command string, remove it
            reply = strrep(reply,commandString,'');

            success=true;
        end

    end %close methods

end %close classdef 
