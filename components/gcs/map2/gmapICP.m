function o = gmapICP(im, xim, yim, p, win);

if nargin < 5,
  win = 40;
end

pmean = mean(p, 2);
xplim = pmean(1) + [-win win];
yplim = pmean(2) + [-win win];

threshold = 50;
pmap = gmapPoints(im, xim, yim, xplim, yplim, 50);

c0 = scan_correlation(pmap, p);

ofit = scan_icp_irls(p, pmap, [0 0 0]', 5.0);
pfit = o_mult(ofit, p);
c1 = scan_correlation(pmap, pfit);

disp(sprintf('gmapICP: %d->%d',c0(3), c1(3)));

%plot(pmap(1,:),pmap(2,:),'g.', p(1,:),p(2,:),'b.', ...
%     pfit(1,:), pfit(2,:),'r.');

if (c1(3) > c0(3)+100),
  o = ofit;
else
  o = [0 0 0]';
end
