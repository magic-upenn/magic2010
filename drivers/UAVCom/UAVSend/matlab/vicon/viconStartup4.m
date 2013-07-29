%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%viconStartup
%Nov 7, 2011: for use with viconAPI2
vicon_ip = '192.168.129.65';
vicon_port = 800;

ViconAPI2('connect',vicon_ip,vicon_port);
pause(0.5)
vdata = ViconAPI2('get_data',0.001);

num_subjects = size(vdata(end).subjects,1);

%rate of the vicon data
viconrate = 100;

for c=1:nquad
    for jj=1:num_subjects
        if(strcmp(qd{c}.name,vdata(end).subjects(jj).name))
            qd{c}.viconid = jj;
            qd{c}.vtime = GetUnixTime;
        end
    end
end