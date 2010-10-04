function radioselect(source,eventdata)

global GDISPLAY

switch(get(eventdata.NewValue,'String'))
case 'Strong'
  GDISPLAY.selectedTemplate = 1;
case 'Moderate'
  GDISPLAY.selectedTemplate = 2;
case 'Weak'
  GDISPLAY.selectedTemplate = 3;
case 'Red Bin'
  GDISPLAY.selectedOOI = 1;
case 'Red Person'
  GDISPLAY.selectedOOI = 2;
case 'Yellow Bin'
  GDISPLAY.selectedOOI = 3;
case 'Door'
  GDISPLAY.selectedOOI = 4;
case 'Car'
  GDISPLAY.selectedOOI = 5;
end
