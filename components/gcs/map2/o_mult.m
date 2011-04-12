function o = o_mult(o1, o2)
% Compose transform parameters.
% i.e. solves for transformation T_o = T_o1*T_o2

ca = cos(o1(3,:));
sa = sin(o1(3,:));

o(1,:) = o1(1,:) + ca.*o2(1,:) - sa.*o2(2,:);
o(2,:) = o1(2,:) + sa.*o2(1,:) + ca.*o2(2,:);
o(3,:) = o1(3,:) + o2(3,:);
