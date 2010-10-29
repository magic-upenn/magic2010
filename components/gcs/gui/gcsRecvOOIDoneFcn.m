function gcsRecvOOIDoneFcn(data, name)
global GDISPLAY OOI AVOID_REGIONS

if isempty(data)
  return
end

disp('got OOI Done message!');
msg = deserialize(data);

ser = msg.ser;
for i = 1:length(OOI)
  if ser == OOI(i).serial
    if strcmp(msg.status,'complete')
      if OOI(i).type == 1
        OOI(i).type = 2;
      elseif OOI(i).type == 3
        OOI(i).type = 4;
      end
      ooiOverlay();
    else %cancel
      set(GDISPLAY.ooiList,'Value',i);
      ooiDelete();
    end

    %remove corresponding avoid region if one exists
    for j=1:length(AVOID_REGIONS)
      if ser == AVOID_REGIONS(j).serial
        set(GDISPLAY.avoidRegionList,'Value',j);
        avoidRegionDelete();
        break;
      end
    end

    return;
  end
end

