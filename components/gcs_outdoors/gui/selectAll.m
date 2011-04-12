function selectAll()
global GDISPLAY

for i=1:length(GDISPLAY.robotRadioControl)
  if strcmp(get(GDISPLAY.robotRadioControl{i},'Enable'),'on')
    set(GDISPLAY.robotRadioControl{i},'Value',1);
  end
end
