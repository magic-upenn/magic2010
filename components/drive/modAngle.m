function a = modAngle(a);
% Reduces angle to [-pi, pi)

a = mod(a, 2*pi);
ind = (a >= pi);
a(ind) = a(ind)-2*pi;
