function o = o_p1p2(p1, p2);
% Computes odometry parameters from pose p1->poses p2:
% i.e. solves for transformation T_p1*T_o = T_p2

n2 = size(p2, 2);
o = zeros(3,n2);

dx = p2(1,:)-p1(1,:);
dy = p2(2,:)-p1(2,:);
ca = cos(p1(3,:));
sa = sin(p1(3,:));
o(1,:) = ca.*dx + sa.*dy;
o(2,:) = -sa.*dx + ca.*dy;
o(3,:) = modAngle(p2(3,:)-p1(3,:));
