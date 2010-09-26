function SavePIDdata(x, y, theta, vel, w, x_nearest, y_nearest, x_tar, y_tar, theta_des, draw_flag)
persistent dim

if (isempty(dim))
    dim = [];
end

dim = [dim; x y theta w vel x_tar y_tar theta_des];

if(draw_flag)
figure(draw_flag);
clf
plot(dim(:,1), dim(:,2), 'k-');
axis xy; axis equal; hold on;
plot([x x+vel*cos(theta)], [y y+vel*sin(theta)], 'r-');
plot([x x+vel*cos(theta_des)], [y y+vel*sin(theta_des)], 'b-');
plot(x_tar, y_tar, 'g*');
plot([x_nearest x_tar], [y_nearest y_tar], 'g-');
axis([-10.0+x 10.0+x -10.0+y 10.0+y]);
end

save dim dim
end