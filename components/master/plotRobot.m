function h = plotRobot(x, y, heading, id, h)

xFill = .3*[-1.0 2.5 -1.0 -1.0];
yFill = .3*[-1.0 0  1.0 -1.0];

trans = [cos(heading) -sin(heading) x;
	 sin(heading)  cos(heading) y;
	 0 0 1];

pFill = trans*[xFill; yFill; ones(size(xFill))];

if nargin < 5,
  % Create new handles:
  hold on;
  h.shape = fill(pFill(1,:), pFill(2,:), 'g');
  h.text = text(x, y, num2str(id));
  set(h.text, 'HorizontalAlignment', 'center', 'FontSize', 14);
  hold off;
else
  set(h.shape, 'XData',pFill(1,:), 'YData',pFill(2,:));
  set(h.text, 'Position',[x y]);
end
