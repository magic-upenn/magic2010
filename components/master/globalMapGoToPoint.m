function globalMapGoToPoint()

global GDISPLAY ROBOTS

[xp, yp] = ginput(1);

msgName = ['Robot',num2str(GDISPLAY.selectedRobot),'/Goal_Point'];

if ~isempty(xp),
    [xr yr] = gpos_to_rpos(GDISPLAY.selectedRobot, xp(1), yp(1));
    PATH = [xr yr];
    ROBOTS(GDISPLAY.selectedRobot).ipcAPI('publish', msgName, serialize(PATH));
end

