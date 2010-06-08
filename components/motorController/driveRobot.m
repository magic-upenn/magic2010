function driveRobot(id,addr)

SetMagicPaths

if nargin >0
  setenv('ROBOT_ID',sprintf('%d',id));
end

if nargin <2
  addr = sprintf('192.168.10.10%d',id);
end

ipcInit(addr);
motorsInit;

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
    SetVelocity(v,w);
    fprintf(1,'v=%f w=%f\n',v,w);
    pause(0.05);
  end
end