%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%initialize variables

num = 250000; %number of iterations the experiment will run

ViconData = zeros(6,num,nquad); %[roll, pitch, yaw, x, y, z]'
ViconFrame = zeros(1,num); 
VelSave = zeros(3,num,nquad); %velocity [x,y,z]'
timer = zeros(1,num);
DesPosSave = zeros(3,num,nquad);
DesVelSave = zeros(3,num,nquad);
DesEulSave = zeros(3,num,nquad);
DesAccSave = zeros(3,num,nquad);
trpySave = zeros(4,num,nquad); %thrust, roll, pitch, yaw commands
intSave = zeros(4,num,nquad); %integral terms [thrust, roll, pitch, yaw]'

%feedback from the vehicle
OBrpy  = zeros(3,num,nquad);
OBwrpy  = zeros(3,num,nquad);
OBwrpy2  = zeros(3,num,nquad);
OBacc  = zeros(3,num,nquad);
OBrpm = zeros(4,num,nquad);
OBcntr = zeros(1,num,nquad);
OBvoltage = zeros(1,num,nquad);
OBcurrent = zeros(1,num,nquad);

%data from the barometer
BAROtemp = zeros(1,num,nquad);
BAROpressure = zeros(1,num,nquad);
BAROtime = zeros(1,num,nquad);

%killflag is used to kill the experiment.  If killflag==1 then a thrust of 0 is
%sent to the vehicles.  If killflag==0 then operation is normal.  killflag
%starts at 1 and then goes to zero when the Powermate is twisted.  After
%this point killflag is set to 0 if the Powermate is pressed.
killflag = 1;

%startflag goes from 0 to 1 when the Powermate is twisted for the first
%time
startflag = 0;

% viconcntr = 0;
printinterval=100; %how often to print some information about the quads
printcnt = 0;

% seqtypesave = zeros(num,nquad);

for c=1:nquad
    qd{c}.phi = 0;
    qd{c}.theta = 0;
    qd{c}.psi = 0;
    
    qd{c}.euler = zeros(3,1);
    qd{c}.pos = zeros(3,1);
    qd{c}.pos_raw = zeros(3,1);
    qd{c}.vel = zeros(3,1);
    qd{c}.omega = zeros(3,1);
    qd{c}.Rot_last = eye(3);
    qd{c}.framelast = 0;
    qd{c}.viconid = [];
        
    qd{c}.euler_des = zeros(3,1);
    qd{c}.pos_des = zeros(3,1);
    qd{c}.vel_des = zeros(3,1);
    
    %integral terms
    qd{c}.phi_int = 0;
    qd{c}.theta_int = 0;
    qd{c}.th_int = 0;
    qd{c}.yaw_int = 0;
    
    %onboard attitude gains
    qd{c}.onboardkp = [170,170,170];
    qd{c}.onboardkd = [17,17,17];

    qd{c}.vtime = -inf; %the last time a good vicon value was received
    
    qd{c}.safetymode = 0;    %0 is normal, 1 is safety descent, 2 is killed
    qd{c}.yawcmdsafety = 0;  %yaw angle to which quad is commanded during 
                             %safety descent mode, set in safetyLogic.m

    %     qd{c}.stopangletime = 0;
end

safety.th_nano = 65; %in grams
safety.time1 = 0.2; %time before entering the safety mode
safety.time2 = 0.6; %extra time before killing the props after impact

%vehicle must be inside this region to fly
safety.safebox = [-4.0, 4.0, -4.0, 4, -1, 4]; %xmin, xmax, ymin, ymax, zmin, zmax

estimation.tau_pos = 0.02; %time constant for low pass filter on position
estimation.tau_vel = 0.02; %time constant for low pass filter on velocity
estimation.maxvel = 8.0; %max velocity allowed for filter

setitM = zeros(nquad,1); %represents the current mode the vehicle is in
seq_cntM = ones(nquad,1); %which sequence the vehicle is in
seq_timeM = zeros(nquad,1); %time the vehicle entered the current sequence

clear global seqM
load seq_basic

global seqM seq_cntM