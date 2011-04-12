%SetMagicPaths;
cam1Driver = @uvcCam650_1;

% Initialize the front facing cam
cam1Driver('init','/dev/video0');
cam1Driver('stream_on');
cam1Driver('set_ctrl','contrast', 32);


cntr=0;
%imgMsgName = ['Robot1/Video0' VisMarshall('getMsgSuffix','ImageData')];
%imgMsgFormat  = VisMarshall('getMsgFormat','ImageData');
host = 'localhost';
ipcAPIConnect(host);

imgMsgName = 'Robot5/CamFront';
ipcAPIDefine(imgMsgName);

while(1)
  pause(0.03);
  imYuyv = cam1Driver('read');
  if ~isempty(imYuyv)
    cntr      = cntr + 1;
    imRgb     = yuyv2rgbm(imYuyv);
    image(imRgb);
    set(gca,'ydir','normal','xdir','reverse');
    drawnow;
    
    imJpg = cjpeg(imRgb);
    
    packet.img = imJpg;
    packet.imgno = cntr;
    packet.t = GetUnixTime();
        
    ser = serialize(packet);
    
    ipcAPIPublish(imgMsgName,ser);
    fprintf('.');
    %content = VisMarshall('marshall','ImageData',imRgb);
    %ipcAPIPublishVC(imgMsgName,content);
  end
  
  
end




if ~exist('camInit') || (camInit == 0),
  uvcCam('init');
  camInit = 1;
end

uvcCam('stream_on');

uvcCam('set_ctrl','contrast', 32);

for i = 1:100,
  pause(0.030);
  im = uvcCam('read');
  if (~isempty(im)),
   imagesc(im');
   drawnow;
  end
end

uvcCam('stream_off');
