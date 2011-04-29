function loadConfig1()
global POSE LIDAR0 LIDAR1 SERVO1 KINECT ENCODERS


%pose
POSE.xInit      = 0;
POSE.yInit      = 0;
POSE.zInit      = 0;
POSE.rollInit   = 0;
POSE.pitchInit  = 0;
POSE.yawInit    = 0;


%lidar0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LIDAR0.resd    = 0.25;
LIDAR0.res     = LIDAR0.resd/180*pi; 
LIDAR0.nRays   = 1081;
LIDAR0.angles  = ((0:LIDAR0.resd:(LIDAR0.nRays-1)*LIDAR0.resd)-135)'*pi/180;
LIDAR0.cosines = cos(LIDAR0.angles);
LIDAR0.sines   = sin(LIDAR0.angles);
LIDAR0.offsetx = 0.137;
LIDAR0.offsety = 0;
LIDAR0.offsetz = 0.54;  %from the body origin (not floor)

LIDAR0.mask    = ones(size(LIDAR0.angles));
%{
LIDAR0.mask(10:40)    = 0;
LIDAR0.mask(80:120)   = 0;
LIDAR0.mask(970:1010) = 0;
LIDAR0.mask(1050:end) = 0;
%}
% Be very conservative to ensure no interpolated antenna obstacles
LIDAR0.mask(1:140) = 0;
LIDAR0.mask(end-139:end) = 0;
LIDAR0.present = 1;



%lidar1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LIDAR1.resd    = 0.25;
LIDAR1.res     = LIDAR1.resd/180*pi; 
LIDAR1.nRays   = 1081;
LIDAR1.angles  = ((0:LIDAR1.resd:(LIDAR1.nRays-1)*LIDAR1.resd)-135)*pi/180;
LIDAR1.cosines = cos(LIDAR1.angles);
LIDAR1.sines   = sin(LIDAR1.angles);
LIDAR1.mask    = ones(size(LIDAR1.angles));

%offsets are with respect to the servo!!!
LIDAR1.offsetx = 0.064;
LIDAR1.offsety = -0.038;
LIDAR1.offsetz = 0;
LIDAR1.present = 1;

%servo1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SERVO1.offsetx   = 0.165;
SERVO1.offsety   = 0;
SERVO1.offsetz   = 0.40;
SERVO1.amult     = 1; %could be not 1 if servo potentiometer is wearing out
SERVO1.offsetYaw = rad(4);

%kinect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%motors and wheels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

