SetMagicPaths;
addpath ../Xbee/

ipcInit();

ipcAPISubscribe(GetMsgName('SelectedId'))


addr = '192.168.10.19';
port = 12345;

UdpSendAPI('connect',addr,port);

cntr = 1;


uvcCam('init','/dev/video0',[800 600]);
uvcCam('stream_on');
uvcCam('set_ctrl','contrast', 32);

id = GetRobotId();
selectedId = id;
cnt = 0;

while(1)
  msgs = ipcAPI('listen',5);
  nmsgs = length(msgs);
  for ii=1:nmsgs
     selectedId = uint8(msgs(ii).data);
     fprintf('selected robot #%d\n',selectedId);
  end
  
  
  pause(0.0300);
  imYuyv = uvcCam('read');
  if (~isempty(imYuyv)) && (id == selectedId)
   cnt      = cnt + 1;
   imRgb    = yuyv2rgb(imYuyv);
   jpgc     = cjpeg(imRgb);
   data.jpg = jpgc;
   data.t   = GetUnixTime();
   data.id  = sprintf('Robot%d/FrontCam',id);
   data.cnt = cnt;
   payload  = serialize(data);

   UdpSendAPI('send',payload);
   fprintf(1,'send packet of size %d  ',length(payload));
   image(imRgb); drawnow;
  end
  cntr = cntr +1;
end
