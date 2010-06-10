function distance = GetDistfromDisp(disp)

% old parameters distance = (1.613/(0.01355*disp + 0.03485) - 2.375)/3.281;

%distance = (76.75*exp(-1.069*disp) + 14.87*exp(-0.08365*disp) ) / 3.281;
distance = (29.13*exp(-0.396*disp) + 13.81*exp(-0.08042*disp) ) / 3.281; % Robot1:Julia
% in meters
