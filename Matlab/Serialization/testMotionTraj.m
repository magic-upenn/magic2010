
traj1.t    = 1;
traj1.size = 10;
xs = num2cell(1:traj1.size);
ys = num2cell(10+(1:traj1.size));
traj1.waypoints = struct('x',xs,'y',ys);

content = MagicMotionTrajSerializer('serialize',traj1);

traj2 = MagicMotionTrajSerializer('deserialize',content);


