addpath( [ getenv('VIS_DIR') '/ipc' ] )

msgName = 'Robot0/ImuFiltered';

ipcAPIConnect;
ipcAPISubscribe(msgName);


while(1)
  msgs = ipcAPIReceive(10);
  len = length(msgs);
  if len > 0
    for i=1:len
      switch (msgs(i).name)
        case 'Robot0/ImuFiltered'
          imuData =  MagicImuFilteredSerializer('deserialize',msgs(i).data)
        otherwise
          error('unknown message type')
      end
    end
  end
end