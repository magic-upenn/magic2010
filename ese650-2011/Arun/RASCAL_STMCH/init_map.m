function init_map(res,xdev,ydev)

global MAP
MAP.res   = res; %meters

MAP.xmin  = -xdev;  %meters
MAP.ymin  = -ydev;

MAP.xmax  =  xdev;
MAP.ymax  =  ydev;


%dimensions of the map
MAP.sizex  = ceil((MAP.xmax - MAP.xmin) / MAP.res + 1); %cells
MAP.sizey  = ceil((MAP.ymax - MAP.ymin) / MAP.res + 1);

MAP.xpos = MAP.xmin:MAP.res:MAP.xmax; %x-positions of each pixel of the map
MAP.ypos = MAP.ymin:MAP.res:MAP.ymax; %y-positions of each pixel of the map

MAP.map = zeros(MAP.sizey,MAP.sizex,'uint8') + 127;

end

