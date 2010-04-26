addpath( [ getenv('VIS_DIR') '/ipc' ] )
addpath ../mexTools/

cmdMsgName = 'Robot0/VelocityCmd';

ipcAPIConnect;
ipcAPIDefine(cmdMsgName,MagicVelocityCmdSerializer('getFormat'));


v=0;
w=0;

dv=0.05;
dw=0.05;

while(1)
  c = getch();
  
  if ~isempty(c)
    switch c
      case 'w'
        v=v+dv;
      case 's'
        v=v-dv;
      case 'a'
        w=w+dw;
      case 'd'
        w=w-dw;
    end
    
  else
    cmd.v = v;
    cmd.w = w;
    ipcAPIPublishVC(cmdMsgName,MagicVelocityCmdSerializer('serialize',cmd));
    fprintf(1,'v=%f w=%f\n',v,w);
    pause(0.05);
  end
end