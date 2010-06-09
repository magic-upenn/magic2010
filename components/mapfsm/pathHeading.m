function a = pathHeading(x, y);

dx = diff(x);
dy = diff(y);

a = atan2(dy, dx);

a(end+1) = a(end);
