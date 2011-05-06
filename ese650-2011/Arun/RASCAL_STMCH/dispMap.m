function [h,pl] = dispMap(h,pl)
global MAP
%persistent h
if isempty(h)
   figure;
   h = imagesc(MAP.map);
   pl = plot(0,0,'b*');
   set(gca,'ydir','reverse');
   hold on;
else
    set(h,'cdata',MAP.map);
    set(pl,'Xdata',MAP.posex,'Ydata',MAP.posey);
end
end