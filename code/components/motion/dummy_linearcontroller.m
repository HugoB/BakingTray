classdef dummy_linearcontroller < linearcontroller 

    properties (Hidden)
        positionTimer %to simulate the non-instantaneous motion of the stage
        instantMotions = true  %If true, the stages move instantly to target position. If false,
                               %the max speed and update interval are used by the positionTimer to execute
                               %a simple gradual motion. This is used for testing the GUI. 
        updateInterval = 0.05  %every 10 ms update the currentPosition property during a motion
        isStageMoving = false 
        hiddenCurrentPosition % Used to implement a gradual motion with a timer: see obj.updatePosition
        targetPosition
        speed
        verbose=false;
    end

    methods

      % Constructor
      function obj=dummy_linearcontroller(stageObject,logObject) 

        if nargin<1
          stageObject=[];
        end
        if nargin<2
          logObject=[];
        end

        if ~isempty(stageObject)
          obj.attachLinearStage(stageObject);
        end

        if ~isempty(logObject)
            obj.attachLogObject(logObject);
        end

        %This timer is used to simulate the gradual motion of the stage
        obj.positionTimer = timer;
        obj.positionTimer.StartDelay = obj.updateInterval;
        obj.positionTimer.TimerFcn = @(~,~) [] ;
        obj.positionTimer.StopFcn = @(~,~) obj.updatePosition;
        obj.positionTimer.ExecutionMode = 'singleShot';

        obj.setMaxVelocity(25); %Hard-code a fast speed 
        obj.hiddenCurrentPosition=obj.attachedStage.currentPosition;
      end % Constructor

      % Destructor
      function delete(obj)
        if ~isempty(obj.hC)
          obj.hC=[];
        end

        if isa(obj.positionTimer,'timer')
            stop(obj.positionTimer)
        end
        delete(obj.positionTimer)
      end % Destructor


      % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      function success = connect(~)
        success = true;
      end %connect


      % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      function success = isControllerConnected(~)
        success=true;
      end %isControllerConnected


      % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      function pos = axisPosition(obj)
        if ~obj.isAxisReady;
          pos=[];
          return
        end

        thisStage = obj.attachedStage;
        thisStage.currentPosition = obj.hiddenCurrentPosition;
        pos = thisStage.currentPosition;
        if isempty(pos)
          fprintf('WARNING: position of dummy linear stage is reported as empty\n')
        end
      end %axisPosition


      % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      function moving = isMoving(obj,~,~)
        moving=obj.isStageMoving;
      end %isMoving


      % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      function success = relativeMove(obj, distanceToMove)
        success=false;
        if ~obj.isAxisReady
          return
        end

        if ~obj.checkDistanceToMove(distanceToMove)
          return
        end

        %Check that it's OK to move here
        willMoveTo = distanceToMove+obj.axisPosition;

        if ~obj.isMoveInBounds(willMoveTo)
          success=false;
          return
        end

        msg = sprintf('moving by %0.2f mm from %0.2f to %0.2f\n', ...
          distanceToMove, obj.attachedStage.currentPosition, willMoveTo);
        obj.logMessage(inputname(1),dbstack,1,msg);

        if obj.verbose
          fprintf(msg)
        end

        obj.targetPosition=willMoveTo;
        if obj.instantMotions
          obj.hiddenCurrentPosition = obj.targetPosition;
          obj.attachedStage.currentPosition = obj.targetPosition;
        elseif strcmp(obj.positionTimer.Running,'off')
          start(obj.positionTimer)
        end

        success=true;

      end %relativeMove


      % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      function success = absoluteMove(obj, targetPosition)
       success=false;
        if ~obj.isAxisReady
          return
        end

        %Check that it's OK to move here
        if ~obj.isMoveInBounds(targetPosition)
          return
        end

        msg=sprintf('moving to %0.2f\n',targetPosition);
        obj.logMessage(inputname(1),dbstack,1,msg);

        if obj.verbose
          fprintf(msg)
        end

        obj.targetPosition=targetPosition;

        if obj.instantMotions
          obj.hiddenCurrentPosition = obj.targetPosition;
          obj.attachedStage.currentPosition = obj.targetPosition;
        elseif strcmp(obj.positionTimer.Running,'off')
          start(obj.positionTimer)
        end
        success=true;

      end %absoluteMove


      % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      function success = stopAxis(obj, ~)
        success=false;
        if ~obj.isAxisReady;
          return
        end

        obj.logMessage(inputname(1),dbstack,2,'Stopping axis');
        stop(obj.positionTimer)
        obj.targetPosition=obj.hiddenCurrentPosition;

        success=true; 
      end %stopAxis


      % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      function pos = getPositionUnits(~,~)
          pos='mm'; 
      end
      function success=setPositionUnits(~,~,~)
        success=true;
      end


      % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      function minPos=getMinPos(obj)
        minPos=getMinPos@linearcontroller(obj);

        if isempty(minPos)
          obj.logMessage(inputname(1),dbstack,5,'No minPos is defined.')
        end
      end %getMinPos


      function maxPos=getMaxPos(obj)
        maxPos=getMaxPos@linearcontroller(obj);

        if isempty(maxPos)
          obj.logMessage(inputname(1),dbstack,5,'No maxPos is defined.')
        end
      end %getMaxPos


      function success=referenceStage(~)
        success=true;
      end


      function success=isStageReferenced(~)
        success=true;
      end

      % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      % get or set speed and acceleration settings
      % None of these are relevant to the dummer_linearcontroller. 
      function speed = getMaxVelocity(obj,~)
          speed=obj.attachedStage.speed;
      end
      function success = setMaxVelocity(obj,speed,~)
        obj.attachedStage.speed=speed;
        success=true;
      end
      function velocity = getInitialVelocity(~,~)
        velocity=0;
      end
      function success = setInitialVelocity(~,~,~)
        success=true;
      end
      function accel = getAcceleration(~,~)
        accel=1;
      end
      function success = setAcceleration(~,~,~)
        success=true;
      end

      function success=enableAxis(~,~)
        success=true;
      end 
      function success=disableAxis(~,~)
        success=true;
      end


    end %close methods

    methods (Hidden)

        % dummy_linearController specific stuff
        function obj = updatePosition(obj)
            %Increment current position. If we're still not at the correct position, re-start the timer
            obj.isStageMoving=true;
            updateStep = obj.getMaxVelocity*obj.updateInterval;
            if abs(obj.targetPosition-obj.hiddenCurrentPosition)<updateStep
              updateStep = abs(obj.targetPosition-obj.hiddenCurrentPosition);
            end

            if obj.verbose
              fprintf('updateStep: %0.2f; targetPosition: %0.2f; hiddenCurrentPosition: %0.2f\n', ...
                updateStep, obj.targetPosition, obj.hiddenCurrentPosition)
            end
            %Use the hiddenCurrentPosition property so we don't fire any listeners on obj.currentPosition.
            %This will mess up the GUI behavior
            updateStep = updateStep * sign(obj.targetPosition-obj.hiddenCurrentPosition);
            obj.hiddenCurrentPosition = obj.hiddenCurrentPosition+updateStep;
            delta = round(obj.hiddenCurrentPosition-obj.targetPosition);

            if abs(delta)<=updateStep
                obj.hiddenCurrentPosition = obj.targetPosition;
                obj.isStageMoving=false;
                stop(obj.positionTimer)
            elseif strcmp(obj.positionTimer.Running,'off')
                start(obj.positionTimer)
            end
        end
    end %Hidden methods


end %close classdef
