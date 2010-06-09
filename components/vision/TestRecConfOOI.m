SetMagicPaths

ipcInit('192.168.10.19');

ipcAPISubscribe('ConfirmedOOI');


while(1)
   msgs = ipcAPIReceive(10);
   
   len = length(msgs);
   
   for i=1:len
      if msgs(i).name == 'ConfirmedOOI'
              fprintf(1,'got OOI\n');
              confOOI = deserialize(msgs(i).data)
                confOOI.OOI
                confOOI.POSE
      end
   end
    
end
