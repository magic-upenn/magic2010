function distance = GetDistfromYheight(yheight)

% in meters
distance = (55.1*exp(-0.1021*yheight) + 14.69*exp(-0.0146*yheight))/3.281;
