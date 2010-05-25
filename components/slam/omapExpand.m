%expand the map by some number of meters in x and y direction
function omapExpand(x,y)
global OMAP EMAP


if (x==0 && y==0)
  return;
end

%{
new map will look like this

y
^
|m13 m23 m33
|m12 OLD m32
|m11 m21 m31
|---------->x
%}

m21=[];
m12=[];

m32=[];
m23=[];

if (x<0)
  m12 = zeros(ceil(-x*OMAP.invRes),OMAP.map.sizey,'uint8');
elseif (x>0)
  m32 = zeros(ceil(x*OMAP.invRes),OMAP.map.sizey,'uint8');
end

if (y<0)
  m21 = zeros(OMAP.map.sizex,ceil(-y*OMAP.invRes),'uint8');
elseif (y>0)
  m23 = zeros(OMAP.map.sizex,ceil(y*OMAP.invRes),'uint8');
end

m11 = zeros([size(m12,1) size(m21,2)],'uint8');
m31 = zeros([size(m32,1) size(m21,2)],'uint8');
m13 = zeros([size(m12,1) size(m23,2)],'uint8');
m33 = zeros([size(m32,1) size(m23,2)],'uint8');

if (numel(m11)==0), m11=[]; end
if (numel(m31)==0), m31=[]; end
if (numel(m13)==0), m13=[]; end
if (numel(m33)==0), m33=[]; end
  

%{
size(m11)
size(m12)
size(m13)

size(m21)
size(OMAP.map.data)
size(m23)

size(m31)
size(m32)
size(m33)
%}

%colums are xs, rows are xs
OMAP.map.data = [m11     m12       m13;
                 m21 OMAP.map.data m23;
                 m31     m32       m33];
EMAP.map.data = [m11     m12       m13;
                 m21 EMAP.map.data m23;
                 m31     m32       m33];


OMAP.xmin       = OMAP.xmin - size(m12,1)*OMAP.res;
OMAP.ymin       = OMAP.ymin - size(m21,2)*OMAP.res;
OMAP.xmax       = OMAP.xmax + size(m32,1)*OMAP.res;
OMAP.ymax       = OMAP.ymax + size(m23,2)*OMAP.res;

EMAP.xmin       = EMAP.xmin - size(m12,1)*EMAP.res;
EMAP.ymin       = EMAP.ymin - size(m21,2)*EMAP.res;
EMAP.xmax       = EMAP.xmax + size(m32,1)*EMAP.res;
EMAP.ymax       = EMAP.ymax + size(m23,2)*EMAP.res;


OMAP.map.sizex  = (OMAP.xmax - OMAP.xmin) / OMAP.res + 1;
OMAP.map.sizey  = (OMAP.ymax - OMAP.ymin) / OMAP.res + 1;

EMAP.map.sizex  = (EMAP.xmax - EMAP.xmin) / EMAP.res + 1;
EMAP.map.sizey  = (EMAP.ymax - EMAP.ymin) / EMAP.res + 1;

fprintf(1,'Map resized. New dimensions: x(%f %f) y(%f %f)\n', ...
        OMAP.xmin,OMAP.xmax,OMAP.ymin,OMAP.ymax);
