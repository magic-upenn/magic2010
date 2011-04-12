len = size(cam,4);
rate = 10;
dt = 1/rate;

t0 = GetUnixTime();
for ii=1:len
    dt2 = GetUnixTime()-t0;
    ddt = dt-dt2;
    if ddt>0
        usleep(ddt*1000000);
    end
    t0 = GetUnixTime();
    image(cam(:,:,:,ii));
    drawnow;
end