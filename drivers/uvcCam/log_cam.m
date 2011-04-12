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

nLog = 1800;

frames = zeros(240,320,3,nLog,'uint8');
ts     = zeros(1,nLog);
tic
while(1)
  usleep(1000);
  imYuyv = uvcCam('read');
  if ~isempty(imYuyv)
    toc;
    tic;
    cntr      = cntr + 1;
    ts(cntr)  = GetUnixTime();
    imRgb     = yuyv2rgbm(imYuyv);
    frames(:,:,:,cntr) = imRgb;
    
    fprintf(1,'.');
    %image(imRgb); drawnow;
    %content = VisMarshall('marshall','ImageData',imRgb);
    %ipcAPIPublishVC(imgMsgName,content);
    
    if (cntr == nLog)
      fprintf(1,'logging finished\n');
      return
    end
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
