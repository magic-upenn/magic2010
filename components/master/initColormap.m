function initColormap
global MAGIC_COLORMAP

MAGIC_COLORMAP = [];
%free to unknown (white to grayish)
colorHelper([1,1,1], [.6,.65,.7], 101);

% (grayish to yellow)
%colorHelper([.6,.65,.7], [1,1,0], 10);

%temporary obstacles
colorHelper([1,1,0], [.5,0,0], 90);

%sure obstacles
colorHelper([.5,0,0], [0,0,0], 10);

MAGIC_COLORMAP


function colorHelper(c0,c1,s)
global MAGIC_COLORMAP

step = (c1-c0)./(s-1);
red   = c0(1):step(1):c1(1);
green = c0(2):step(2):c1(2);
blue  = c0(3):step(3):c1(3);
if(length(red) ~= s)
  red = c0(1)*ones(1,s);
end
if(length(green) ~= s)
  green = c0(2)*ones(1,s);
end
if(length(blue) ~= s)
  blue = c0(3)*ones(1,s);
end
new_map = [red' green' blue'];
MAGIC_COLORMAP = [MAGIC_COLORMAP;new_map];


