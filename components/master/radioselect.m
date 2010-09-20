function radioselect(source,eventdata)

global GDISPLAY

switch(get(eventdata.NewValue,'String'))
case 'Robot 1'
  GDISPLAY.selectedRobot = 1;
case 'Robot 2'
  GDISPLAY.selectedRobot = 2;
case 'Robot 3'
  GDISPLAY.selectedRobot = 3;
case 'Robot 4'
  GDISPLAY.selectedRobot = 4;
case 'Robot 5'
  GDISPLAY.selectedRobot = 5;
case 'Robot 6'
  GDISPLAY.selectedRobot = 6;
case 'Robot 7'
  GDISPLAY.selectedRobot = 7;
case 'Robot 8'
  GDISPLAY.selectedRobot = 8;
end
GDISPLAY.selectedRobot
