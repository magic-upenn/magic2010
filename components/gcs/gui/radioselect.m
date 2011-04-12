function radioselect(source,eventdata)

global GDISPLAY

switch(get(eventdata.NewValue,'String'))
case 'Strong'
  GDISPLAY.selectedTemplate = 1;
case 'Moderate'
  GDISPLAY.selectedTemplate = 2;
case 'Weak'
  GDISPLAY.selectedTemplate = 3;
case 'Red Barrel'
  GDISPLAY.selectedOOI = 1;
case 'Red Barrel (Neutralized)'
  GDISPLAY.selectedOOI = 2;
case 'Moving POI'
  GDISPLAY.selectedOOI = 3;
case 'Moving POI (Neutralized)'
  GDISPLAY.selectedOOI = 4;
case 'Stationary POI'
  GDISPLAY.selectedOOI = 5;
case 'Yellow Barrel'
  GDISPLAY.selectedOOI = 6;
case 'Door'
  GDISPLAY.selectedOOI = 7;
case 'Car'
  GDISPLAY.selectedOOI = 8;
end
