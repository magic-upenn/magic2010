SetMagicPaths

host = 'localhost';
ipcAPIConnect(host);

imgMsgName = 'Robot1/CamFront';
ipcAPISubscribe(imgMsgName);

while(1)
  msgs = ipcAPIReceive(10);
  
  len = length(msgs);
  
  for ii=1:len
    fprintf('got camera message\n');
    imRgb = djpeg(msgs(ii).data);
    imRgb = imRgb(end:-1:1,end:-1:1,:);
    
    %set(gca,'ydir','normal','xdir','reverse');
    
        
    imY = rgb2ycbcr(imRgb);
    stats = find_red_candidates(imY(:,:,3));
    stats = stats(1,:)
		stats(:,2:end) = round(stats(:,2:end));

    bb = stats(1,2:end);
    bcolor = uint8([255 255 255]);
    %imgRgb = draw_box(imRgb,bb,bcolor);
    if (stats(1) > 3000 && (stats(3)-stats(2)) > 30)
      imRgb(bb(1):bb(1)+3,bb(3):bb(4),1) = 0;
      imRgb(bb(1):bb(1)+3,bb(3):bb(4),2) = 255;
      imRgb(bb(1):bb(1)+3,bb(3):bb(4),3) = 0;
      
      imRgb(bb(2)-3:bb(2),bb(3):bb(4),1) = 0;
      imRgb(bb(2)-3:bb(2),bb(3):bb(4),2) = 255;
      imRgb(bb(2)-3:bb(2),bb(3):bb(4),3) = 0;
      
      imRgb(bb(1):bb(2),bb(3):bb(3)+3,1) = 0;
      imRgb(bb(1):bb(2),bb(3):bb(3)+3,2) = 255;
      imRgb(bb(1):bb(2),bb(3):bb(3)+3,3) = 0;
      
      imRgb(bb(1):bb(2),bb(4)-3:bb(4),1) = 0;
      imRgb(bb(1):bb(2),bb(4)-3:bb(4),2) = 255;
      imRgb(bb(1):bb(2),bb(4)-3:bb(4),3) = 0;
    end
    image(imRgb);
    drawnow;
  end
end