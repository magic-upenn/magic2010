function globalMapStop()

global GDISPLAY

for i=1:length(GDISPLAY.robotRadioControl)
  if get(GDISPLAY.robotRadioControl{i},'Value')
    sendStateEvent(i,'stop');
  end
end
