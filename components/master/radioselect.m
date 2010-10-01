function radioselect(source,eventdata)

global GDISPLAY

switch(get(eventdata.NewValue,'String'))
case 'Strong'
  GDISPLAY.selectedTemplate = 1;
case 'Moderate'
  GDISPLAY.selectedTemplate = 2;
case 'Weak'
  GDISPLAY.selectedTemplate = 3;
end
