function h = dispMap(h)
global MAP
%persistent h
if isempty(h)
   figure;
   h = imagesc(MAP.map);
   hold on;
else
    set(h,'cdata',MAP.map);
end
end