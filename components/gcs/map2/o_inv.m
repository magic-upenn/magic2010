function o = o_inv(o1);
% Compute inverse of o1 transformation parameters.
% i.e. T_o*T_o1 = eye

ca = cos(o1(3,:));
sa = sin(o1(3,:));

o = [-ca.*o1(1,:) - sa.*o1(2,:); ...
     +sa.*o1(1,:) - ca.*o1(2,:); ...
     -o1(3,:)];
