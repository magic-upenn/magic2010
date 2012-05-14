%choose the robot 
track = track1;

%take the difference in positions
dtrackx = diff(track(:,2));
dtracky = diff(track(:,3));

%distance traveled each update (second)
dtrack  = sqrt(dtrackx.^2 + dtracky.^2);

%integrate the incremental distance
dist = sum(dtrack,1)
