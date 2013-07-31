%SetMagicPaths;
addr = '192.168.10.110';
port = 12345;
UdpReceiveAPI('connect',addr,port);
icntr = 0;
t0 = GetUnixTime();
colormap gray;
count=0;
%dat=[];

num_frames=40;
while((count<=num_frames))
  msgs = UdpReceiveAPI('receive');
  if ~isempty(msgs)
    count=count+1;
    msg=msgs(1);
    data=msg.data;
    imu=double(typecast(data(1:48),'single'));
    img=djpeg(data(49:end));
    imshow(img);
    dat{count}=img;
    drawnow;
    pause(.5)
	fprintf('Took frame %d\n', count);
  end
end
save('/tmp/images.mat','dat')
