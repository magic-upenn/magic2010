function candOOIOverlay()
global GDISPLAY CAND_OOI

if ~isempty(GDISPLAY.visualCandOOIOverlay)
  delete(GDISPLAY.visualCandOOIOverlay);
end
GDISPLAY.visualCandOOIOverlay = [];

if get(GDISPLAY.candOOIOverlay,'Value') && ~isempty(CAND_OOI)
  set(0,'CurrentFigure',GDISPLAY.hFigure);

  th=0:0.1:2*pi;
  x=[cos(th)];
  y=[sin(th)];
  c=[.3 .3 .3];

  temp_x = CAND_OOI.x;
  temp_y = CAND_OOI.y;
  GDISPLAY.visualCandOOIOverlay = patch(temp_x+x,temp_y+y,c);
end

