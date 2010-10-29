function shiftAxes(hAxes, x, y, threshold)

if nargin < 4,
  threshold = .2;
end

xlim = get(hAxes,'XLim');
ylim = get(hAxes,'YLim');

xrange = xlim(2)-xlim(1);
yrange = ylim(2)-ylim(1);

xrel = (x-xlim(1))/xrange;
yrel = (y-ylim(1))/yrange;
if ((xrel > threshold) && (xrel < 1-threshold) && ...
    (yrel > threshold) && (yrel < 1-threshold))
  return;
end

xlim1 = x + xrange.*[-.5 .5];
ylim1 = y + yrange.*[-.5 .5];
set(hAxes, 'XLim', xlim1, 'YLim', ylim1);
