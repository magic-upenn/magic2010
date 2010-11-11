function o = gmapFitCorr(im, xim, yim, p, win);

if nargin < 5,
  win = 10;
end

xs = [-win:0.10:win];
ys = [-win:0.10:win];
cim = map_correlation(im, xim, yim, p, xs, ys);
[cmax, imax, jmax] = max2(cim);

xsfit = xs(imax);
ysfit = ys(jmax);
disp(sprintf('gmapFitCorr: (%.1f, %.1f) = %d', xsfit, ysfit, cmax));

if (cmax > 10000)
  o = [xsfit ysfit 0]';
else
  o = [0 0 0]';
end

%{
h = gcf;
figure(3)
imagesc(cim);
figure(h);
%}

return;


pmean = mean(p, 2);
xplim = pmean(1) + [-win win];
yplim = pmean(2) + [-win win];

threshold = 50;
pmap = gmapPoints(im, xim, yim, xplim, yplim, 50);

c0 = scan_correlation(pmap, p);

ofit = scan_icp_irls(p, pmap, [0 0 0]', 20.0);
pfit = o_mult(ofit, p);
c1 = scan_correlation(pmap, pfit);

disp(sprintf('gmapICP: %d->%d',c0(3), c1(3)));

h = gcf;
figure(3)
plot(pmap(1,:),pmap(2,:),'g.', p(1,:),p(2,:),'b.', ...
     pfit(1,:), pfit(2,:),'r.');
figure(h);

%if (c1(3) > c0(3)+100),
if (c1(3) > c0(3)+20),
  o = ofit;
else
  o = [0 0 0]';
end
