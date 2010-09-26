function dX = planarrobotmotion(t, X, vel, w)
% ode solver equations
dX = zeros(3,1);
dX(1) = vel* cos(X(3));
dX(2) = vel*sin(X(3));
dX(3) = w;
end