SetMagicPaths;
addpath ../Xbee/

addr = '127.0.0.1';
port = 12345;

UdpSendAPI('connect',addr,port);

cntr = 1;


uvcCam('init');
uvcCam('stream_on');
uvcCam('set_ctrl','contrast', 32);


while(1)
  pause(0.0300);
  imYuyv = uvcCam('read');
  if (~isempty(imYuyv))
   imRgb = yuyv2rgb(imYuyv);
   jpgc = cjpeg(imRgb);
   data.jpg = jpgc;
   data.t   = GetUnixTime();
   payload = serialize(data);
   UdpSendAPI('send',payload);
   fprintf(1,'send packet of size %d  ',length(payload));
  end
  cntr = cntr +1;
end