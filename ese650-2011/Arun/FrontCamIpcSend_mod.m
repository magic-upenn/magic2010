cntr=0;

host = 'localhost';
ipcAPIConnect(host);

imgMsgName = 'Robot5/CamFront';
ipcAPIDefine(imgMsgName);

while(1)
  pause(0.03);
  imRgb = get_image(1);
  if ~isempty(imRgb)
    cntr      = cntr + 1;
    imRgb     = yuyv2rgbm(imYuyv);
    %image(imRgb);
    %set(gca,'ydir','normal','xdir','reverse');
    %drawnow;
    
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

uvcCam('stream_off');
