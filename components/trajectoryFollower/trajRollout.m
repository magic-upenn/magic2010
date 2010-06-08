
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simple trajectory follower
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trajFollower(tUpdate)
tic
if nargin < 1,
  tUpdate = 0.05;
end

trajFollowerStart;

loop = 1;
while (loop),
  %pause(tUpdate);
  trajFollowerUpdate;
end

trajFollowerStop;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize trajectory follower process
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trajFollowerStart
clear all;
global TRAJ POSE
SetMagicPaths;
%{
figure(9);
clf
plot(0,0,'kx');
axis equal xy;
axis([-1 3 -2 2]);



pts = getline(gca); %path;
hold on
plot(pts(:,1),pts(:,2),'r-');
hold off

for idx = 1:size(pts,1)-1
  path.waypoints(idx).x = pts(idx,1);
  path.waypoints(idx).y = pts(idx,2);
  path.waypoints(idx).yaw = atan2(pts(idx+1,2)-pts(idx,2), pts(idx+1,1)-pts(idx,1));
  path.waypoints(idx).v = [];
end

idx = idx+1;
path.waypoints(idx).x = pts(idx,1);
path.waypoints(idx).y = pts(idx,2);
path.waypoints(idx).yaw = path.waypoints(idx-1).yaw;

path.size = size(pts,1);
path.t = [];
%}
TRAJ.path = []; % path;%vertcat([0:.1:2;zeros(1,21)]', [2*ones(1,11);0:.1:1]');
%plot(TRAJ.path.waypoints(:,1),TRAJ.path.waypoints(:,2));
%drawnow;
TRAJ.path_idx = 1;
TRAJ.turning = false;
TRAJ.last_u = [0,0];
TRAJ.last_pose = [0,0,0];
TRAJ.sum_e = 0;
TRAJ.last_e = 0;
TRAJ.traj = -1;
TRAJ.best_traj = -1;
TRAJ.vw=[];
TRAJ.count = 0;
%TRAJ.fout = fopen('debug_log.txt','w');
POSE.data = [];

vels = [.2 .4 .6]';
w = [pi/32:pi/32:pi/8 pi/8:pi/8:pi/2]';
for i = 1:size(vels, 1)
  if (i==1) 
    validw = [floor(size(w,1)/4) floor(size(w,1)/2)];
  else
    validw =[1:size(w,1)]; 
  end
  for j = 1:size(validw,2)
    TRAJ.vw = [TRAJ.vw; vels(i) w(validw(j)); vels(i) 0; vels(i) -w(validw(j))];
  end
end
TRAJ.vw = unique(TRAJ.vw,'rows');


%connect to ipc on localhost
ipcInit;
ipcReceiveSetFcn(GetMsgName('Pose'),        @ipcRecvPoseFcn);
ipcAPISetMsgQueueLength(GetMsgName('Pose'), 1);
ipcReceiveSetFcn(GetMsgName('Trajectory'),  @ipcRecvTrajFcn);
ipcAPISetMsgQueueLength(GetMsgName('Trajectory'), 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Message handler for a new trajectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ipcRecvTrajFcn(data,name)
global TRAJ

fprintf(1,'got traj message\n');
TRAJ.path = MagicMotionTrajSerializer('deserialize',data);
TRAJ.path_idx = 1; %reset where we are on the path


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Receive and handle ipc messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trajFollowerUpdate
ipcReceiveMessages(50);

function ipcRecvPoseFcn(data,name)

global POSE

if ~isempty(data)
  POSE.data = MagicPoseSerializer('deserialize',data);
  %{
  if(POSE.handle ~= -1)
    delete(POSE.handle);
  end
  figure(1)
  hold on;
  POSE.handle = plot(POSE.data.x,POSE.data.y,'bx');
  temp = 20;
  axis([POSE.data.x-temp POSE.data.x+temp POSE.data.y-temp POSE.data.y+temp]);
  drawnow;
  %}
end
dt = toc;
tic
if (dt>0.1)
    fprintf(1,'large delay (%f)!!!!!!\n',dt);
end
trajFollowerFollow(dt);




function trajFollowerFollow(dt)
global TRAJ POSE

if isempty(TRAJ.path) || isempty(POSE.data) || TRAJ.path.size < 1
  fprintf('path or pose is empty!\n');
  return
end


K_OBS = 1;
K_VEL = 1/5;
K_DIST = 2;
K_THETA_DIFF = .5;

path_idx = TRAJ.path_idx;
path = TRAJ.path;
pose = [POSE.data.x, POSE.data.y, POSE.data.yaw];

predicted_pos = forwardSimulate(TRAJ.last_u(1),TRAJ.last_u(2),dt,pose);
%TRAJ.history = [TRAJ.history;pose(1:3),predicted_pos(1:3)];
%fprintf(TRAJ.fout,'predicted=(%f %f %f) actual=(%f %f %f) u=(%f %f) dt=%f\n',predicted_pos(1:3),pose(1:3),TRAJ.last_u(1:2),dt);
%[pose(1:3),predicted_pos(1:3)]

[start_idx, start_dist] = findClosestPoint(TRAJ.path_idx, pose, path);
TRAJ.path_idx = start_idx;
path_idx = start_idx;

if(path_idx == numel(path.waypoints) && start_dist < 0.3)
    fprintf('Done!\n');
    u=[0,0];
    return;
end

best_score = inf;
best_idx = -1;
rollout = [];

if(abs(pose(3))>pi)
  pose(3) = sign(pose(3))*mod(abs(pose(3)),2*pi)
  if(pose(3) > pi)
      pose(3) = pose(3) - 2*pi;
  elseif(pose(3) < -pi)
      pose(3) = pose(3) + 2*pi;
  end
end

%fprintf('path point = %f %f startidx  = %i\n', path.waypoints(start_idx,:), start_idx);
if(path_idx == numel(path.waypoints))
    angleToLine = atan2(path.waypoints(start_idx).y-pose(2),path.waypoints(start_idx).x-pose(1)) - pose(3);
else
    angleToLine = atan2(path.waypoints(start_idx+1).y-path.waypoints(start_idx).y,path.waypoints(start_idx+1).x-path.waypoints(start_idx).x) - pose(3);
end
if(angleToLine > pi)
    angleToLine = angleToLine - 2*pi;
elseif(angleToLine < -pi)
    angleToLine = angleToLine + 2*pi;
end

if(abs(angleToLine) >= pi/2)
    TRAJ.turning = true;
elseif(abs(angleToLine) <= pi/10)
    TRAJ.turning = false;
end

timestep = 1.0;
max_idx = start_idx;
if(~TRAJ.turning)
  for i=1:size(TRAJ.vw,1)
    v = TRAJ.vw(i,1);
    w = TRAJ.vw(i,2);
    new_pos = forwardSimulate(v,w,timestep,pose);

            [p_idx, p_dist] = findClosestPoint(start_idx, new_pos, path);
%fprintf('v=%f w=%f p_idx=%d p_dist=%f new_pos=(%f %f %f)\n', v, w, p_idx, p_dist, new_pos(1:3)); 
            if(p_idx == -1)% || map(round(new_pos(2)/0.1),round(new_pos(1)/0.1)) > 252)
                continue
            end
            if(p_idx > max_idx)
              max_idx = p_idx;
            end

            theta_diff = new_pos(3)-path.waypoints(p_idx).yaw;
            if(theta_diff > pi)
                theta_diff = theta_diff - 2*pi;
            elseif(theta_diff < -pi)
                theta_diff = theta_diff + 2*pi;
            end
            theta_diff = abs(theta_diff);
            

            %s = K_DIST*p_dist + K_OBS*map(round(new_pos(2)/0.1),round(new_pos(1)/0.1)) + K_VEL*1/(v+1);
            s = K_DIST*p_dist + K_THETA_DIFF*theta_diff + K_VEL*1/(v+1);
            %s = K_DIST*p_dist + K_VEL*1/(v+1);
            if(s < best_score)
                best_score = s;
                best_idx = p_idx;
                best_control = [v,w];
                best_new_pos = new_pos;
            end
            rollout = [rollout;new_pos(1),new_pos(2)];
        %end
    end
else
%special case for turning in place
angleToLine
    dir = sign(angleToLine);
    if(dir==0)
        dir = 1;
    end
    for w=3*pi/8:pi/16:pi/2 %was pi/8 to pi/4
        v=0;
        ang = dir*w*timestep;
        new_pos = [pose(1:2), pose(3)+ang];

        a = angleToLine-new_pos(3);
        if(a > pi)
            a = a - 2*pi;
        elseif(a < -pi)
            a = a + 2*pi;
        end

        s = abs(a);
        if(s <= best_score)
            %fprintf('whoa!\n');
            best_score = s;
            best_control = [v,dir*w];
            best_new_pos = new_pos;
        end
    end
end
%fprintf('pos=(%f, %f, %f) rollout=(%f, %f, %f)\n',pose(1:3),best_new_pos(1:3));


if(best_score == inf)
    fprintf('ERROR: No solution!\n');
    u = [0,0];
    return
else
    u = best_control;
end

%{
if(~TRAJ.turning)
  fprintf(TRAJ.fout,'start=(%f, %f, %f) rollout_pt=(%f, %f, %f) target_pt=(%f, %f, %f)\n',path.waypoints(start_idx).x,path.waypoints(start_idx).y,path.waypoints(start_idx).yaw,best_new_pos(1:3),path.waypoints(best_idx).x,path.waypoints(best_idx).y,path.waypoints(best_idx).yaw);
  min_idx = start_idx-3;
  if(min_idx < 1)
    min_idx = 1;
  end
  for print_i=min_idx:max_idx
    fprintf(TRAJ.fout,'path_idx=%d (%f, %f, %f)\n',print_i,path.waypoints(print_i).x,path.waypoints(print_i).y,path.waypoints(print_i).yaw);
  end
end

figure(9);
hold on;
plot(pose(1),pose(2),'bx');
plot([pose(1), pose(1)+ 0.1*cos(pose(3))],[pose(2), pose(2) + 0.1*sin(pose(3))],'g-');


TRAJ.count = TRAJ.count+1;
%if (mod(TRAJ.count,10)==-1) 
if(TRAJ.traj~=-1)
  delete(TRAJ.traj);
  TRAJ.traj=-1;
end
if(TRAJ.best_traj~=-1)
  delete(TRAJ.best_traj);
end
%hold on
if(numel(rollout))
  TRAJ.traj=plot(rollout(:,1),rollout(:,2),'x');
end
TRAJ.best_traj=plot(best_new_pos(1),best_new_pos(2),'ro');
%hold off
%axis equal
%axis([0 2.5 -0.5 1.25]); 
drawnow
%end
hold off;
%}


%feedback
actual_v = sqrt(sum((pose(1:2)-TRAJ.last_pose(1:2)).^2))/dt;
ang = pose(3)-TRAJ.last_pose(3);
if(ang > pi)
    ang = ang - 2*pi;
elseif(ang < -pi)
    ang = ang + 2*pi;
end
actual_w = ang/dt;
actual_u = [actual_v,actual_w];

e = TRAJ.last_u - actual_u;
TRAJ.sum_e = TRAJ.sum_e + e;

kp = [0,0];
ki = [0,0];
kd = [0,0];

u_p = kp.*e;
u_i = ki.*TRAJ.sum_e;
if (abs(u_i) > 1) 
  u_i= sign(u_i);
end
u_d = kd.*(TRAJ.last_e-e);
u_ff = u;
%fprintf('pose=%f last=%f ang=%f actual_u=(%f,%f) last_u=(%f,%f) e=(%f,%f)\n',pose(3), TRAJ.last_pose(3),ang,actual_u, TRAJ.last_u, e);
%fprintf('p=(%f,%f) i=(%f,%f) d=(%f,%f) ff=(%f,%f)\n',u_p,u_i,u_d,u_ff);
u = u_p + u_i + u_d + u_ff;

%fprintf(1,'sending vels %f %f\n',u(1:2));

%send out velocity
TRAJ.last_u = u_ff;
TRAJ.last_pose = pose;
TRAJ.last_e = e;
%fprintf('v=%f,w=%f\n',u(1:2));
if(mod(TRAJ.count,10)==-1)
  SetVelocity(0,0);
  disp('paused');
  pause;
end
SetVelocity(u(1),u(2)/2);


function [min_pt, min_dist] = findClosestPoint(start_idx, pose, path)
min_pt = -1;
min_dist = 10000;
%min_dist = (path.waypoints(start_idx,1)-pose(1))^2+(path.waypoints(start_idx,2)-pose(2))^2;
for i=start_idx:numel(path.waypoints)
    d = (path.waypoints(i).x-pose(1))^2+(path.waypoints(i).y-pose(2))^2;
    if(d<=min_dist)
        min_dist = d;
        min_pt = i;
    elseif(d>min_dist)
        break;
    end
end

if(min_pt==numel(path.waypoints))
    min_dist = sqrt(min_dist);
else
    x1=path.waypoints(min_pt).x;
    y1=path.waypoints(min_pt).y;
    x2=path.waypoints(min_pt+1).x;
    y2=path.waypoints(min_pt+1).y;
    %min_dist =  abs((x2-x1)*(y1-pose(2))-(x1-pose(1))*(y2-y1))/sqrt((x2-x1)^2+(y2-y1)^2);
    r_numerator = (pose(1)-x1)*(x2-x1) + (pose(2)-y1)*(y2-y1);
    r_denomenator = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1);
    r = r_numerator / r_denomenator;
    s =  ((y1-pose(2))*(x2-x1)-(x1-pose(1))*(y2-y1) ) / r_denomenator;
    distanceLine = abs(s)*sqrt(r_denomenator);
    if ( (r >= 0) && (r <= 1) )
      min_dist = distanceLine;
    else
      dist1 = (pose(1)-x1)*(pose(1)-x1) + (pose(2)-y1)*(pose(2)-y1);
      dist2 = (pose(1)-x2)*(pose(1)-x2) + (pose(2)-y2)*(pose(2)-y2);
      if (dist1 < dist2)
        min_dist = sqrt(dist1);
      else
        min_dist = sqrt(dist2);
      end
    end
end

function new_pos = forwardSimulate(v,w,timestep,pose)
if(w ~= 0)
  r = v/abs(w);
  angle = w*timestep;
  alpha = pose(3) + sign(w)*pi/2;
  offset = [-r*cos(alpha); -r*sin(alpha)];
  rot = [cos(angle) -sin(angle)
  sin(angle)  cos(angle)];
  new_pos = ((rot*offset) + pose(1:2)' - offset)';
  new_pos(3) = pose(3) + angle;
else
  new_pos = pose(1:3) + v*timestep*[cos(pose(3)), sin(pose(3)), 0 ];
end

