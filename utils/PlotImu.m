function PlotImu(vals,ts)
persistent rs ps ys wxs wys wzs axs ays azs
persistent hrs hps hys hwxs hwys hwzs haxs hays hazs

len = 1000;

if isempty(rs)
  rs  = zeros(1,len);
  ps  = zeros(1,len);
  ys  = zeros(1,len);
  wxs = zeros(1,len);
  wys = zeros(1,len);
  wzs = zeros(1,len);
  axs = zeros(1,len);
  ays = zeros(1,len);
  azs = zeros(1,len);
  
  %rpy
  figure(1000);
  clf(gcf);
  
  hrs = plot(rs,'r'); hold on;
  hps = plot(ps,'g');
  hys = plot(ys,'b'); hold off;
  
  %accelerometer values
  figure(1001);
  clf(gcf);
  
  haxs = plot(axs,'r'); hold on;
  hays = plot(ays,'g');
  hazs = plot(azs,'b'); hold off;
  
end

len2 = size(vals,2);

rs = [rs((len2+1):end) vals(1,:)];
ps = [ps((len2+1):end) vals(2,:)];
ys = [ys((len2+1):end) vals(3,:)];

axs = [axs((len2+1):end) vals(4,:)];
ays = [ays((len2+1):end) vals(5,:)];
azs = [azs((len2+1):end) vals(6,:)];

set(hrs,'ydata',rs);
set(hps,'ydata',ps);
set(hys,'ydata',ys);

set(haxs,'ydata',axs);
set(hays,'ydata',ays);
set(hazs,'ydata',azs);
drawnow;



