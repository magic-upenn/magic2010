%SetMagicPaths;
cam2Driver = @uvcCam650_2;

% Initialize the omni
cam2Driver('init','/dev/cam_omni');
cam2Driver('stream_on');
cam2Driver('set_ctrl','contrast', 32);

cntr_omni = 0;

host = 'localhost';
ipcAPIConnect(host);

imgMsgName_omni = 'Robot5/CamOmni';
ipcAPIDefine(imgMsgName_omni);

while(1)
    pause(0.03);
    imYuyv_omni = cam2Driver('read');
    if ~isempty(imYuyv_omni)
        cntr_omni      = cntr_omni + 1;
        imRgb_omni     = yuyv2rgbm(imYuyv_omni);
        %image(imRgb_omni);
        %set(gca,'ydir','normal','xdir','reverse');
        %drawnow;

        imJpg_omni = cjpeg(imRgb_omni);

        packet_omni.img = imJpg_omni;
        packet_omni.imgno = cntr_omni;
        packet_omni.t = GetUnixTime();

        ser_omni = serialize(packet_omni);

        ipcAPIPublish(imgMsgName_omni,ser_omni);
        fprintf(',');
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
