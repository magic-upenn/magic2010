function h = drawPose(h,x,y,yaw,size)

xvals = [x + size*cos(yaw);x + size*cos(yaw+2.7);x + size*cos(yaw-2.7)];
yvals = [y + size*sin(yaw);y + size*sin(yaw+2.7);y + size*sin(yaw-2.7)];

if isempty(h)
    h = patch(xvals,yvals,'r');
else
    %set(h,'xdata',xvals,'ydata',yvals);
    delete(h);
    h = patch(xvals,yvals,'r');
end

end