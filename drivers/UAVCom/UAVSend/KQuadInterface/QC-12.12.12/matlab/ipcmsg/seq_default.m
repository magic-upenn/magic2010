%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function seq = seq_default()

%PARAMETERS:

%seq(1).onboardkp - the roll, pitch, and yaw proportional gains for the
%onboard attitude controller in units of grams/radian

%seq(1).onboardkd - roll, pitch, and yaw derivative gains for the onboard
%attitude controller in units of grams/(rad/sec)

%seq(1).safety_thrust - the constant thrust applied if the vehicle loses
%tracking.  See safetyLogic.m.  This should be less than the weight!

%seq(1).safety_accelz - the estimated downward acceleration of the vehicle
%when the safety_thrust is applied

%The z position controller is defined with respect to:

%m - mass of the vehicle in kilograms
%wn_z - natural frequency of z position controller
%xi_z - damping ratio of z position controller

%The x and y position controllers are designed to be critically damped with 
%and are designed with respect to:

%tauxy - approximate rise time of the controller

%The units for the gains of z position controllers are as follows:

%kp_z - Newtons/meter
%kd_z - Newtons/(meter/sec)
%ki_z - Newtons/(meter*sec)

%and for x and y:

%kp_x - radians/meter
%kd_x - radians/(meter/sec)
%ki_x - radians/(meter*sec)

if(0)
    %Mega quad   
    tauxy = 0.8;
    m =2.5;
    xi_z = 1.1;
    wn_z = 4;
    kp_z = m*wn_z^2;
    kd_z = 2*xi_z*wn_z*m;
    
    seq(1).onboardkp = [1600,1600,3000];
    seq(1).onboardkd = [185,185,150];
    
    seq(1).safety_thrust = 1500;
    seq(1).safety_accelz = 0.14*9.81;
elseif(0)
    %deka quad   
    tauxy = 0.8;
    m =0.6;
    xi_z = 1.1;
    wn_z = 4;
    kp_z = m*wn_z^2;
    kd_z = 2*xi_z*wn_z*m;
    
    seq(1).onboardkp = [400,400,470];
    seq(1).onboardkd = [30,30,50];
    
    seq(1).safety_thrust = 500;
    seq(1).safety_accelz = 0.14*9.81;
elseif(1)
    %new nano quad
    tauxy = 0.8;
    
    m =0.16;
    xi_z = 1;
    wn_z = 6;
    kp_z = m*wn_z^2;
    kd_z = 2*xi_z*wn_z*m;
    
    seq(1).onboardkp = [550,550,800];
    seq(1).onboardkd = [42,42,50];
    
    seq(1).safety_thrust = 100;
    seq(1).safety_accelz = 0.11*9.81;
else
    %nano quad
    tauxy = 0.7;

    m =0.075;
    xi_z = 1;
    wn_z = 6;
    kp_z = m*wn_z^2;
    kd_z = 2*xi_z*wn_z*m;
    
    seq(1).onboardkp = [333.2,333.2,170];
    seq(1).onboardkd = [16.66,16.66,10];

    seq(1).safety_thrust = 65;
    seq(1).safety_accelz = 0.11*9.81;
end
    
seq(1).kp_x = 0.35/(tauxy^2);
seq(1).kd_x = 0.35/(tauxy);
seq(1).ki_x = 0.5*0.35/(tauxy);
seq(1).kp_y = 0.35/(tauxy^2);
seq(1).kd_y = 0.35/(tauxy);
seq(1).ki_y = 0.5*0.35/(tauxy);
seq(1).kp_z = kp_z;
seq(1).kd_z = kd_z;
seq(1).ki_z = kd_z*0.5;
seq(1).ki_yaw = 0.2; %integral gain for yaw control

seq(1).th_base = m*9.81; %base thrust for z position control (Newtons)
seq(1).maxangle = 45*pi/180;

seq(1).name = [];
seq(1).type = [];
seq(1).pos = [];
seq(1).psi = [];
seq(1).speed = []; 
seq(1).time = [];

seq(1).use_posdes = []; %use the desired position instead of the actual postion for certain control modes
seq(1).unixtime = [];

seq(1).zeroint = [];
seq(1).trpy = [];
seq(1).resetgains = [];
seq(1).useint = [];
seq(1).accelrate = [];

seq(1).skipx = [];
seq(1).skipy = [];
seq(1).skipz = [];
seq(1).kpyawset = [];
seq(1).trpyuseint = [];

