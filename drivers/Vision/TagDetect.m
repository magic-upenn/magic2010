clear all
close all
addpath '../UAVReceive/ReceiveBluefoxMEX'

addr='192.168.10.110';
port=12345;
UdpReceiveAPI('connect',addr,port);
t0=GetUnixTime();
colormap gray;
dimensions=[240 376];
bw=ones(240,376)*255;


prevcorners=[1 1];
corners=[1 1];

%% imu packet structure
%time, roll, pitch, yaw, wroll, wpitch, wyaw, ax, ay, az, pressure,
%magnetometer
vec=1:100;
rollval=zeros(1,length(vec));
pitchval=rollval;
yawval = rollval;
wrollval = rollval;
wpitchval = rollval;
wyawval = rollval;
axval = rollval;
ayval = rollval;
azval = rollval;
pressval = rollval;
figure(1)

while(1)
    msgs=UdpReceiveAPI('receive');
    if ~isempty(msgs)
        msg=msgs(1);
        data=msg.data;
        imu=double(typecast(data(1:48),'single'));
        im=djpeg(data(49:end));
        
        rollval(1:end-1)=rollval(2:end);
        rollval(end)=imu(2);
        pitchval(1:end-1)=pitchval(2:end);
        pitchval(end)=imu(3);
        yawval(1:end-1)=yawval(2:end);
        yawval(end)=imu(4);
        wrollval(1:end-1)=wrollval(2:end);
        wrollval(end)=imu(5);
        wpitchval(1:end-1)=wpitchval(2:end);
        wpitchval(end)=imu(6);
        wyawval(1:end-1)=wyawval(2:end);
        wyawval(end)=imu(7);
        axval(1:end-1)=axval(2:end);
        axval(end)=imu(8);
        ayval(1:end-1)=ayval(2:end);
        ayval(end)=imu(9);
        azval(1:end-1)=azval(2:end);
        azval(end)=imu(10);
        pressval(1:end-1)=pressval(2:end);
        pressval(end)=press2alt(imu(11));
        
        
        if (size(im,3) > 1)
            im = rgb2gray(im);
        end
        corners = corner(im, 'Harris','SensitivityFactor',0.04,'QualityLevel',0.15,'FilterCoefficients',fspecial('gaussian',[5 1],1.5));
        bw(prevcorners(:,1),prevcorners(:,2))=0;
        bw(corners(:,1),corners(:,2))=1;
        %{
        [H T R]=hough(bw, 'RhoResolution',3);
        numpeaks=100;
        h_thres=0.1*max(H(:));
        P=houghpeaks(H,numpeaks, 'Threshold',h_thres);
        L_orig = houghlines(bw,T,R,P,'MinLength',20);
%}
        %draw image
        figure(1)
        cla
        imshow(im);
        hold on
        plot(corners(:,1),corners(:,2),'rx');
        drawnow
%{        
        %draw roll pitch yaw
        figure(2)
        cla
        plot(vec,rollval,'r-')
        hold on
        plot(vec,pitchval,'g-')
        plot(vec,yawval,'b-')
        drawnow
        
        %draw roll pitch yaw rates
        figure(3)
        cla
        plot(vec,wrollval,'r-')
        hold on
        plot(vec,wpitchval,'g-')
        plot(vec,wyawval,'b-')
        drawnow
        
        %draw acceleration
        figure(4)
        cla
        plot(vec,axval,'r-')
        hold on
        plot(vec,ayval,'g-')
        plot(vec,azval,'b-')
        drawnow
        
        %draw pressure sensor
        figure(5)
        cla
        plot(vec,pressval,'r-')
        drawnow
   %}     
    else
        %fprintf('No packet received\n');
    end
end