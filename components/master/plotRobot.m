function plotRobot(x, y, heading, id)

persistent hShape hText;

xFill = .3*[-1.0 2.5 -1.0 -1.0];
yFill = .3*[-1.0 0  1.0 -1.0];

trans = [cos(heading) -sin(heading) x;
	 sin(heading)  cos(heading) y;
	 0 0 1];

pFill = trans*[xFill; yFill; ones(size(xFill))];

if length(hShape) < id || isempty(hShape{id}),
  hold on;
  hShape{id} = fill(pFill(1,:), pFill(2,:), 'g');
  hText{id} = text(x, y, num2str(id));
  set(hText{id}, 'HorizontalAlignment', 'center', 'FontSize', 14);
  hold off;
else
  set(hShape{id}, 'XData',pFill(1,:), 'YData',pFill(2,:));
  set(hText{id}, 'Position',[x y]);
end
