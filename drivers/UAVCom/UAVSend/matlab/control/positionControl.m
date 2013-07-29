%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%positionControl
%takes in desired position and velocity and acc and computes desired roll
%and pitch angles and thrust

if(~isempty(seqM(qn).seq(seq_cntM(qn)).th_base))
    th_base = seqM(qn).seq(seq_cntM(qn)).th_base;
else
    th_base = 0;
end

th_cmd = th_base+kp_z*(qd{qn}.pos_des(3)-qd{qn}.pos(3)) + ...
    kd_z*(qd{qn}.vel_des(3) - qd{qn}.vel(3))+qd{qn}.th_int;
ux = kp_x*(qd{qn}.pos_des(1)-qd{qn}.pos(1)) + ...
    kd_x*(qd{qn}.vel_des(1)-qd{qn}.vel(1));
uy = kp_y*(qd{qn}.pos_des(2)-qd{qn}.pos(2)) + ...
    kd_y*(qd{qn}.vel_des(2)-qd{qn}.vel(2));

phides = ux*sin(qd{qn}.euler(3)) - uy*cos(qd{qn}.euler(3)) + qd{qn}.phi_int;
thetades = ux*cos(qd{qn}.euler(3)) + uy*sin(qd{qn}.euler(3)) + qd{qn}.theta_int;

if(~isempty(seqM(qn).seq(seq_cntM(qn)).maxangle))
    phides = max(min(phides,seqM(qn).seq(seq_cntM(qn)).maxangle),-seqM(qn).seq(seq_cntM(qn)).maxangle);
    thetades = max(min(thetades,seqM(qn).seq(seq_cntM(qn)).maxangle),-seqM(qn).seq(seq_cntM(qn)).maxangle);
end

DesPosSave(:,j,qn) = qd{qn}.pos_des;
DesVelSave(:,j,qn) = qd{qn}.vel_des;
DesEulSave(:,j,qn) = [phides,thetades,0]';

Force = th_cmd; %this is the force in Newtons
limitForce;
forceingrams = Force/9.81*1000;

if(isempty(seqM(qn).seq(seq_cntM(qn)).kpyawset))
    yawcmd = qd{qn}.euler_des(3) + qd{qn}.yaw_int;
elseif(seqM(qn).seq(seq_cntM(qn)).kpyawset==0)
    yawcmd = qd{qn}.euler_des(3) + qd{qn}.yaw_int;
else
    yawcmd = 0;
end

trpy = [forceingrams, phides, thetades, yawcmd];

%set desired angular velocity to zero
drpy = [0 0 0];
