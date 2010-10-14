function h = plotRobot(x, y, heading, id, servo, h)
global GCS

xFill = .3*[-1.0 2.5 -1.0 -1.0];
yFill = .3*[-1.0 0  1.0 -1.0];
fov_ang = 67.5/2*pi/180;
fov_len = 3.0;
xLine = .3*[2.5+fov_len*cos(fov_ang+servo) 2.5 2.5+fov_len*cos(-fov_ang+servo)];
yLine = .3*[fov_len*sin(fov_ang+servo) 0 fov_len*sin(-fov_ang+servo)];

trans = [cos(heading) -sin(heading) x;
	 sin(heading)  cos(heading) y;
	 0 0 1];

pFill = trans*[xFill; yFill; ones(size(xFill))];
pLine = trans*[xLine; yLine; ones(size(xLine))];

if nargin < 6,
  % Create new handles:
  hold on;
  if any(GCS.sensor_ids==id)
    h.shape = fill(pFill(1,:), pFill(2,:), 'g');
  else
    h.shape = fill(pFill(1,:), pFill(2,:), 'm');
  end
  h.text = text(x, y, num2str(id));
  set(h.text, 'HorizontalAlignment', 'center', 'FontSize', 14);
  h.fov = line(pLine(1,:),pLine(2,:),'LineWidth',2.0);
  hold off;
else
  set(h.shape, 'XData',pFill(1,:), 'YData',pFill(2,:));
  set(h.fov, 'XData', pLine(1,:), 'YData', pLine(2,:));
  set(h.text, 'Position',[x y]);
end
