%CallFromARTHROSYNC('/media/dados/dev/projects/matlab/AutoCalibration/data/repeatability_ARTHRO_2mm/','10')

function CallFromARTHROSYNC (directory,dirtosave,gridsize)

dirlist = dir(directory);
dirtocalibrate = sprintf('%s%s/',directory,dirlist(length(dirlist)).name)
AutoCalibGUI('ARTHROSYNC',dirtocalibrate,dirtosave,gridsize);
% keyboard
% disp('hghkgfhgfjhfgf')