function ooiDelete()
global GDISPLAY OOI

if length(OOI) == 0
  return;
end

id = get(GDISPLAY.ooiList,'Value');

if length(OOI) == 1
  OOI = [];
elseif id == length(OOI)
  OOI = OOI(1:end-1);
  set(GDISPLAY.ooiList,'Value',id-1);
elseif id == 1
  OOI = OOI(2:end);
else
  OOI = [OOI(1:id-1) OOI(id+1:end)];
end

set(GDISPLAY.ooiList,'String',1:length(OOI));

ooiOverlay();
