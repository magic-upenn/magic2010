function slam(tUpdate)

if nargin < 1,
  tUpdate = 0.01;
end

slamStart;

while (1),
  slamReceiveMsgs
  slamUpdate;
end

slamStop;


function slamStart
global SLAM MAPS POSE LIDAR0

SetMagicPaths;

ipcAPIConnect;

DefineLidarMsgs;
DefineEncoderMsg;
DefineVisMsgs;


LIDAR0.msgName = [GetRobotName '/Lidar0'];
LIDAR0.resd    = 0.25;
LIDAR0.res     = LIDAR0.resd/180*pi; 
LIDAR0.nRays   = 1081;
LIDAR0.angles  = ((0:LIDAR0.resd:(LIDAR0.nRays-1)*LIDAR0.resd)-135)'*pi/180;
LIDAR0.cosines = cos(LIDAR0.angles);
LIDAR0.sines   = sin(LIDAR0.angles);
LIDAR0.t       = [];

ENCODERS.msgName = [GetRobotName '/Encoders'];

ipcAPISubscribe(LIDAR0.msgName);
ipcAPISubscribe(ENCODERS.msgName);


%obstacle map
MAPS.omap.res        = 0.05;
MAPS.omap.xmin       = -5;
MAPS.omap.ymin       = -5;
MAPS.omap.xmax       = 25;
MAPS.omap.ymax       = 25;
MAPS.omap.zmin       = 0;
MAPS.omap.zmax       = 5;

MAPS.omap.map.sizex  = (MAPS.omap.xmax - MAPS.omap.xmin) / MAPS.omap.res;
MAPS.omap.map.sizey  = (MAPS.omap.ymax - MAPS.omap.ymin) / MAPS.omap.res;
MAPS.omap.map.data   = zeros(MAPS.omap.map.sizex,MAPS.omap.map.sizey,'uint8');
MAPS.omap.msgName    = [GetRobotName '/omap2d_map2d'];


%exploration map
MAPS.emap            = MAPS.omap;
MAPS.emap.map.data   = 127*ones(MAPS.emap.map.sizex,MAPS.emap.map.sizey,'uint8');
MAPS.emap.msgName    = [GetRobotName '/emap2d_map2d'];


PublishObstacleMap;
PublishExplorationMap;

ScanMatch2D('setBoundaries',xmin,ymin,xmax,ymax);
ScanMatch2D('setResolution',res);


POSE.x     = 0;
POSE.y     = 0;
POSE.z     = 0;
POSE.roll  = 0;
POSE.pitch = 0;
POSE.yaw   = 0/180*pi; %1.5


function slamUpdate
global LIDAR0 ENCODERS
msgs = ipcAPI('listen',25);
nmsgs = length(msgs);

for mi=1:nmsgs
  switch msg(mi).name
    case LIDAR0.msgName
      lidarScan = MagicLidarScanSerializer('deserialize',msgs(i).data);
      slamProcessLidar;
    case ENCODERS.msgNAme
      slamProcessEncoders;
  end
end


function slamUpdate
global SLAM MAPS POSE LIDAR0
 
nmsgs = length(msgs);
  
  for mi=1:nmsgs
    msg = msgs(mi);
    switch msg.name
      case lidarMsgName
        lidarScan = MagicLidarScanSerializer('deserialize',msg.data);
        ranges = double(lidarScan.ranges)';
        fprintf('.');
        freshLidar=1;
    end
  

    freshLidar=0;

    i=i+1;
    pose = [0 0 0];

    indGood = ranges >0.25;

    xs = ranges.*cosines;
    ys = ranges.*sines;
    zs = zeros(size(xs));

    xsss=xs(indGood);
    ysss=ys(indGood);
    zsss=zs(indGood);
    onez=ones(size(xsss));





    xsh = xsss(1:5:end);
    ysh = ysss(1:5:end);

    %[h_trans angles rhos]

     a_center = 0; %pi/2;
    a_range  = pi/2;
    a_res = pi/200;
    r_center =0;
    r_range = 5;
    r_res   = 0.10;


    [h_trans] = HoughTransformAPI(xsh,ysh,a_center,a_range,a_res,r_center, r_range, r_res);

    h_trans(h_trans<10) = 0;
    hh = sum(h_trans,1);



    if isempty(hhPrev)
      hhPrev = hh;
    end

    cshift = -5:5;
    clen = length(cshift);
    cvals= zeros(clen,1);
    for s=1:clen;
      cvals(s) = sum(hh'.*(circshift(hhPrev',cshift(s))));
    end

    [cmax cimax] = max(cvals);
    hhPrev = hh;

    %toc


    if (isempty(mapp))
      T = rotz(yaw);
      X = [xsss'; ysss';zsss';onez'];
      Y=T*X;

      xss = Y(1,:)' +x;
      yss = Y(2,:)' +y;
      zss = Y(3,:)' +z;

      xis = ceil((xss - xmin) * invRes);
      yis = ceil((yss - ymin) * invRes);
      indGood = (xis > 1) & (yis > 1) & (xis < sizex) & (yis < sizey);

      inds = sub2ind(size(map),xis(indGood),yis(indGood));
      mapp(inds) = 100;

      %emap = zeros(size(map),'uint8');
      %emap(245:255,245:255) = 249;

      continue;
    end



    %fprintf(1,'------------------------');

    nyaw= 21;
    nxs = 11;
    nys = 11;

    dyaw = 0.25/180.0*pi;
    dx   = 0.02;
    dy   = 0.02;

    aCand = (-10:10)*dyaw+yaw ; %+ (-cshift(cimax))*a_res;
    xCand = (-5:5)*dx+x;
    yCand = (-5:5)*dy+y;

    hits = ScanMatch2D('match',mapp,xsss,ysss,xCand,yCand,aCand);


    [hmax imax] = max(hits(:));
    [kmax mmax jmax] = ind2sub([nxs,nys,nyaw],imax);

    yaw = aCand(jmax);
    x   = xCand(kmax);
    y   = yCand(mmax);
    positions(:,i) = [x;y;yaw];

    T = (trans([x y 0])*rotz(yaw))';
    X = [xsss ysss zsss onez];
    Y=X*T;


    xss = Y(:,1);
    yss = Y(:,2);

    xis = ceil((xss - xmin) * invRes);
    yis = ceil((yss - ymin) * invRes);

    xl = ceil((x-xmin) * invRes);
    yl = ceil((y-ymin) * invRes);


    %tic
    [eix eiy] = getMapCellsFromRay(xl,yl,xis,yis);
    %toc

    %plot(eix,eiy,'r.'), hold on
    %plot(xis,yis,'b.'), drawnow, hold off


    cis = sub2ind(size(mapp),eix,eiy);
    mape.map.data(cis) = mape.map.data(cis)+1;

    %emap(cis) = 249;

    ptemp.x = x;
    ptemp.y = y;
    ptemp.theta = yaw;

    if (mod(i,3)==0)
      %publishMaps(mapp,emap,ptemp);
      content = VisMap2DSerializer('serialize',mape);
      ipcAPIPublishVC(mapMsgName,content);
    end

    %{
    p.x =x;
    p.y =y;
    p.yaw = yaw;
    publishPose(p)
    %}
    %imagesc(emap); drawnow
    %imagesc(mapp); drawnow
    %}

    indGood = (xis > 1) & (yis > 1) & (xis < sizex) & (yis < sizey);
    inds = sub2ind(size(map),xis(indGood),yis(indGood));

    mapp(inds)= mapp(inds)+1;

    if (mod(i,50)==0)
      indd=mapp<50 & mapp > 0;
      mapp(indd) = mapp(indd)*0.95;
      mapp(mapp>100) = 100;
    end

    if (mod(i,1)==0)
      vpose = [x y 0.05 pose(1) -pose(2) yaw];
      content = VisMarshall('marshall','Pose3D',vpose);
      ipcAPIPublishVC(poseMsgName,content);
    end

    if (mod(i,10)==0)
      lxs = xss';
      lys = yss';
      lzs = zeros(size(lxs));
      lrs = zeros(size(lxs));
      lgs = ones(size(lxs));
      lbs = 0.5*ones(size(lxs));
      las = ones(size(lxs));
      data = [lxs; lys; lzs; lrs; lgs; lbs; las];

      content = VisMarshall('marshall', lidarPointsTypeName,data);
      ipcAPIPublishVC(lidarPointsMsgName,content);
    end

    %{
    if (mod(i,500)==0)
      inds = find((mapp(:) > 0));
      [subx suby] = ind2sub(size(map),inds);

      surfUpdate.heightData.size = length(inds);
      surfUpdate.xs.size = surfUpdate.heightData.size;
      surfUpdate.ys.size = surfUpdate.heightData.size;

      surfUpdate.heightData.data = single(mapp(inds))/100;
      surfUpdate.xs.data = uint32(subx);
      surfUpdate.ys.data = uint32(suby);

      content = VisSurface2DUpdateSerializer('serialize',surfUpdate);
      ipcAPIPublishVC(surfUpdateMsgName,content);
    end
    %}

    if (mod(i,10)==0)

      %set(hMap,'cdata',mapp');

      inds = find((mapp(:) > 50));
      mape.map.data(inds) = 0;
      [subx suby] = ind2sub(size(map),inds);

      %position
      vxs = subx'*res + xmin;
      vys = suby'*res + ymin;
      vzs = 0.01*ones(size(vxs));

      %color information
      vrs = double((mapp(inds)/100)');
      vgs = 1-vrs;
      vbs = 0.2*ones(size(vxs));
      vas = 0.5*ones(size(vxs));

      data = [vxs; vys; vzs; vrs; vgs; vbs; vas];

      content = VisMarshall('marshall', pointCloudTypeName,data);
      ipcAPIPublishVC(pointCloudMsgName,content);


      %{
      surface.heightData.data = single(mapp)/100;
      content = VisSurface2DSerializer('serialize',surface);
      ipcAPIPublishVC(surfMsgName,content);
      %}
    end

    %set(h,'xdata',xss,'ydata',yss);
    %drawnow;
  end
end


