function tr = o_matrix(o);
% Compute transformation matrix of o.

da = o(3);
tr = [cos(da) -sin(da) o(1);
      sin(da) cos(da)  o(2);
      0 0 1];
