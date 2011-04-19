robotId = '5';
OmniCamMsgName = ['Robot' robotId '/CamOmni'];               % Omni-directional Cam
ipcAPIConnect('localhost');
ipcAPISubscribe(OmniCamMsgName);

ct_Omni = 1;
prev_omni_img = [];
while(1)
      msgs = ipcAPIReceive(50);
      len = length(msgs);
      if len > 0
          %tic;
          disp('receiving...');
          for i=1:len
              OmniCam{ct_Omni} = deserialize(msgs(i).data);
                 if(isempty(prev_omni_img))
                    Omni_img = djpeg(OmniCam{ct_Omni}.img);
                    prev_omni_img = linear_unroll(Omni_img,cx,cy,rmax);
                    %omni image
                    hfig = figure;
                    hdl_omni = imagesc(djpeg(OmniCam(ct_Omni).img));
                    homni = figure;
                    hdl_unr = imagesc(prev_omni_img);
                    hval = figure;
                    hdl_yawval = plot(0,0,'r.');
                    ct_Omni = ct_Omni+1;
                    continue;
                else
                    Omni_img = djpeg(OmniCam{ct_Omni}.img);
                    curr_omni_img = linear_unroll(Omni_img,cx,cy,rmax);
                    %tic
                    yaw_est(ct_Omni) = yaw_match(prev_omni_img,curr_omni_img,yaw_range);
                    %toc
                    prev_omni_img = curr_omni_img;
                    set(hdl_unr,'Cdata',curr_omni_img);
                    set(hdl_omni,'Cdata',Omni_img);
                    yy = get(hdl_yawval,'Ydata');
                    set(hdl_yawval,'Xdata',1:ct_Omni,'Ydata',[yy yaw_est(ct_Omni)]);
                    ct_Omni = ct_Omni+1;
                 end
          end
      end
end