SetMagicPaths;

encMsgName = 'Robot2/Encoders';
host = '192.168.10.102';

ipcAPIConnect(host);
ipcAPISubscribe(encMsgName);

encoders=zeros(6,1e4);

while(1)
  msgs = ipcAPIReceive(10);
  len = length(msgs);
  if len > 0
    for i=1:len
      n=n+1;
      packet = MagicEncoderCountsSerializer('deserialize',msgs(i).data)
      encoders(1,n) = packet.t;
      encoders(2,n) = packet.cntr;
      encoders(3,n) = packet.fr;
      encoders(4,n) = packet.fl;
      encoders(5,n) = packet.rr;
      encoders(6,n) = packet.rl;
      %fprintf(1,'.');
    end
  end
end