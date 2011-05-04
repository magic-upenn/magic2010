function h = drawPathN(h,path)
global MAP

path = meters2cells_cont(path(:,1:2),[MAP.xmin,MAP.ymin],MAP.res);

if isempty(h)
    h = plot(path(:,1),path(:,2),'g');
else
    set(h,'xdata',path(:,1),'ydata',path(:,2));
end

end