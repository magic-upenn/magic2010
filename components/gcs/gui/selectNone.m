function selectNone()
global GDISPLAY

for i=1:length(GDISPLAY.robotRadioControl)
  set(GDISPLAY.robotRadioControl{i},'Value',0);
end
