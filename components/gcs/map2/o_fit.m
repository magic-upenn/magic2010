function o = o_fit(x1, x2, w, wheading, omin, omax);
% Fits odometry transformation for poses x1 to poses x2
% with sample weights w, heading fit wheading.

if nargin < 6,
  omax = [inf; inf; inf];
end
if nargin < 5,
  omin = [-inf; -inf; -inf];
end
if nargin < 4,
  wheading = 0;
end
if nargin < 3,
  w = ones(1,size(x1,2));
end


% Weightings
w = w(:)';
sw = sum(w);
ww = [w; w];
wv1 = ww.*x1(1:2,:);
wv2 = ww.*x2(1:2,:);

% Statistics for heading fit
whx = sum(w.*cos(x2(3,:)-x1(3,:)));
why = sum(w.*sin(x2(3,:)-x1(3,:)));

% First fit optimal rotation with no translation:
wv21 = wv2*x1(1:2,:)';
ay = wv21(1,2) - wv21(2,1) - wheading*why;
ax = wv21(1,1) + wv21(2,2) + wheading*whx;
a = -atan2(ay, ax);

% Limit rotation angle:
a = min(max(a, omin(3)), omax(3));

% Compute optimal translation given fixed rotation:
rota = [cos(a) -sin(a);
        sin(a) cos(a)];
to = (sum(wv2,2) - rota*sum(wv1,2))./sw;

% Limit translation parameters:
to = min(max(to, omin(1:2)), omax(1:2));

% Return 3x1 parameters:
o = [to; a];
