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


xtarl = [0:.1:9.9 10:-.1:-9.9 -10*ones(1,201)  ];
ytarl = [0:.1:9.9 10*ones(1,200) 10:-.1:-10 ];



% xtarl = [0 1 2 3 4 5 6 7 8 9 10 9 8 7 6 5 4 3 2 1 0 -1 -2 -3 -4 -5 -6 -7 -8 -9 -10 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -8 -7 -6 -5 -4 -3 -2 -1  0  1  2  3  4  5  6  7  8  9 10  9  9  9  8  8  8  7  7  7  6  6  6  5  4  3  2  1  0 -1 -2 -3 -4 -5 -4 -3 -2 -1  0  1  2  3  4  5  6  7  8  9 10 ];
% ytarl = [0 1 2 3 4 5 6 7 8 9 9  9 9 9 9 9 9 9 9 9 9  9  9  9  9  9  9  9  9  9   9  8  7  6  5  4  3  2  1  0 -1 -2 -3 -4 -5 -6 -7 -8 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -8 -7 -6 -5 -4 -3 -2 -1  0  1  2  3  4  3  3  2  1  0 -1 -2 -2 -3 -4 -4 -4 -3 -3 -3 -2 -2 -2 -1 -1 -1  0  0  0  0 ];

for (j=2:size(xtarl,2))
    x_tar = xtarl(j);
    y_tar = ytarl(j);
    
    if x_tar > 9
        pause(.1);
    end
    
    %for(i=1:200)
        start_time = tic;
        theta_des = atan2(ytarl(j) - y, xtarl(j)-x);
        path_pts = [xtarl(j-1) ytarl(j-1); xtarl(j) ytarl(j)]; 
        w = w_PID(theta, theta_des, x, y, path_pts);
        
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
      velnoisemax =0.1;
      wnoisemax =0.1;
      
      if (w > 3)
          w = 3;
      elseif (w < -3)
          w = -3;
      end
           
        [t X] = ode45(@planarrobotmotion, [0 timestep], [ x y theta],[],normrnd(vel, velnoisemax), normrnd(w, wnoisemax));
        %[t X] = ode45(@planarrobotmotion, [0 timestep], [ x y theta],[],vel, w);
        theta = normrnd(X(end,3), wnoisemax);
        x = X(end,1);
        y =X(end,2);
        
        % add errors
    %    theta = theta + .1;
        SavePIDdata(x,y, theta, vel, w, xtarl(j-1), ytarl(j-1),xtarl(j), ytarl(j), theta_des, 6);
        elap_time = toc(start_time);
        pause(.1 - elap_time);
  %  end
    
%     y_tar = rand*20.0 - 10.0;
%     x_tar = rand*20.0 - 10.0;
    
end