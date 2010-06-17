id = 2;
setenv('ROBOT_ID',sprintf('%d',id));

host = '192.168.10.102';
ipcAPIConnect(host);

for i=-13:13
    for j=1:75
        SetVelocity(i/10,0);
        pause(0.04)
    end
    SetVelocity(0,0);
    pause(1)
end