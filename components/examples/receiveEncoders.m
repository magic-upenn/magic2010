SetMagicPaths;

encMsgName = GetMsgName('Encoders');

ipcAPIConnect;
ipcAPISubscribe(encMsgName);


while(1)
  msgs = ipcAPIReceive(10);
  len = length(msgs);
  if len > 0
    for i=1:len
      encoders = MagicEncoderCountsSerializer('deserialize',msgs(i).data)
      %fprintf(1,'.');
    end
  end
end