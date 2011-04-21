cntr_omni = 0;

host = 'localhost';
ipcAPIConnect(host);

imgMsgName_omni = 'Robot5/CamOmni';
ipcAPIDefine(imgMsgName_omni);

while(1)
    pause(0.03);
    imRgb_omni = get_image(0);
    if ~isempty(imRgb_omni)
        cntr_omni      = cntr_omni + 1;
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

uvcCam('stream_off');
