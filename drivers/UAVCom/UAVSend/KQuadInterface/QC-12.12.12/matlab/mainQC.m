%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%Jun 27, 2012
%run a quadrotor experiment
clear all
close all

%initialize the variables
addpath('./init/')
init_exp

for j=1:num
    %update the timer
    timer(j) = GetUnixTime - time0;
    
    %get the positions and estimate the velocities of the vehicles
    GetQuadPositions
    
    %compute the control for the vehicles and send it out
    DoQuadControl
    
    %get ipc messages to change the sequence or kill the experiment
    GetIPCMessages
    
    %get feedback from the onboard computer on the vehicles
    GetQuadFeedback
end