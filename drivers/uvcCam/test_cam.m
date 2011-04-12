addpath( [ getenv('VIS_DIR') '/ipc' ] )
addpath ~/svn/kQuad/trunk/utils/

uvcCam('init','/dev/video0');
uvcCam('stream_on');
uvcCam('set_ctrl','contrast', 32);

cntr=0;

%{
host = 'localhost';
ipcAPIConnect(host);
imgMsgName = ['Robot1/Video0' VisMarshall('getMsgSuffix','ImageData')];
imgMsgFormat  = VisMarshall('getMsgFormat','ImageData');
ipcAPIDefine(imgMsgName,imgMsgFormat);
%}


while(1)
  usleep(30000);
  imYuyv = uvcCam('read');
  if ~isempty(imYuyv)
    cntr      = cntr + 1;
    imRgb     = yuyv2rgbm(imYuyv);
    image(imRgb);
    set(gca,'ydir','normal','xdir','reverse');
    drawnow;
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
