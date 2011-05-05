function h = dispMap(h)
global MAP
%persistent h
if isempty(h)
   figure;
   h = imagesc(MAP.map);
   set(gca,'ydir','reverse');
   hold on;
else
    set(h,'cdata',MAP.map);
end
end