clear all
clc

% PID test script
timestep = .1;
y_tar = 100;
x_tar = 30;
theta= 0;

x = 0;
y=0;
w = 0;
%vel = 0;
vel = 1;

xlist = [];
ylist = [];

xtarl = [10 -10 -10  10  5 -5 10 -10];
ytarl = [10  10 -10 -10  5 -5  0   0];

for (j=1:size(xtarl,2))
    x_tar = xtarl(j);
    y_tar = ytarl(j);
    for(i=1:200)
        start_time = tic;
        theta_des = atan2(y_tar - y, x_tar-x);
        w = w_PID(theta, theta_des);
        
        %randomly don't turn at all
%         if (rand < .2)
%             w =0;
%             wnoisemax = 0;
%         elseif (rand < .5)
%             w = .2*w;
%             wnoisemax = .03;
%             velnoisemax = .1;  % variance of vel
%         else
%             wnoisemax = .3;
%             velnoisemax = .1;  % variance of vel
%         end
      velnoisemax =0;
      wnoisemax =0;
        
        [t X] = ode45(@planarrobotmotion, [0 timestep], [ x y theta],[],normrnd(vel, velnoisemax), normrnd(w, wnoisemax));
        %[t X] = ode45(@planarrobotmotion, [0 timestep], [ x y theta],[],vel, w);
        theta = normrnd(X(end,3), wnoisemax);
        x = X(end,1);
        y =X(end,2);
        
        % add errors
        theta = theta + .1;
        SavePIDdata(x,y, theta, vel, w, x_tar, y_tar, theta_des, 6);
        elap_time = toc(start_time);
        pause(.1 - elap_time);
    end
    
%     y_tar = rand*20.0 - 10.0;
%     x_tar = rand*20.0 - 10.0;
    
end