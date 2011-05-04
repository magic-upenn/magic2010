function ret = sInitial(event, varargin)

%global POSE
persistent tt;

ret = [];
switch event
 case 'entry'
  disp('sInitial: Waiting for initial pose');
  tt = gettime;
  setVelocity(0,0);
 case 'exit'
    
 case 'update'
    if(gettime - tt > 0.5)
    %if ~isempty(POSE),
        disp('Got pose estimate from UKF');
        ret = 'pose';
    end

end
