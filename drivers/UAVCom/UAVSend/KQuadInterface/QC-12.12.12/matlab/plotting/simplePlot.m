%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%plot some data from a quadrotor experiment

close all
%plotting colors for quadrotors
colorlist = {'r.','g.','b.','m.','y.','c.','k.','b.'};
colorlist = [colorlist,colorlist,colorlist];

haveOBdata = find(OBrpy(1,:,1) | OBrpy(2,:,1) | OBrpy(3,:,1));

for c=1:nquad
    figure(10+c)
    x(1) = subplot(311);
    plot(timer,DesPosSave(1,:,c),'ko')
    hold on
    plot(timer,ViconData(4,:,c),'r.')
    ylabel('x')
    title('Position')
    x(2) =subplot(312);
    plot(timer,DesPosSave(2,:,c),'ko')
    hold on
    plot(timer,ViconData(5,:,c),'r.')
    ylabel('y')
    x(3) = subplot(313);
    plot(timer,DesPosSave(3,:,c),'ko')
    hold on
    plot(timer,ViconData(6,:,c),'r.')
    ylabel('z')
    xlabel('Time')
    linkaxes(x,'x')
    
    figure(20+c)
    x(1) = subplot(311);
    %     plot(timer,DesPosSave(1,:,c),'ko')
    hold on
    plot(timer,ViconData(1,:,c),'r.')
    ylabel('x')
    title('Vicon RPY')
    x(2) =subplot(312);
    %     plot(timer,DesPosSave(2,:,c),'ko')
    hold on
    plot(timer,ViconData(2,:,c),'r.')
    ylabel('y')
    x(3) = subplot(313);
    %     plot(timer,DesPosSave(3,:,c),'ko')
    hold on
    plot(timer,ViconData(3,:,c),'r.')
    ylabel('z')
    xlabel('Time')
    linkaxes(x,'x')
    
    figure
    hold on
    plot((timer),trpySave(1,:,c),'r.')
    plot((timer),trpySave(2,:,c),'g.')
    plot((timer),trpySave(3,:,c),'b.')
    plot((timer),trpySave(4,:,c),'y.')
    title('Commands')
    
    figure(40+c)
    x(1) = subplot(311);
    plot(timer,DesVelSave(1,:,c),'ko')
    hold on
    plot(timer,VelSave(1,:,c),'r.')
    title('Velocity')
    ylabel('x')
    x(2) =subplot(312);
    plot(timer,DesVelSave(2,:,c),'ko')
    hold on
    plot(timer,VelSave(2,:,c),'r.')
    ylabel('y')
    x(3) = subplot(313);
    plot(timer,DesVelSave(3,:,c),'ko')
    hold on
    plot(timer,VelSave(3,:,c),'r.')
    ylabel('z')
    xlabel('Time')
    linkaxes(x,'x')
    
    figure(70+c)
    x(1) = subplot(311);
    plot(timer(haveOBdata),OBwrpy(1,haveOBdata,c),'ko')
    hold on
    %     plot(timer,OBwrpy2(1,:,c),'r.')
    title('Angular Velocity')
    ylabel('x')
    x(2) =subplot(312);
    plot(timer(haveOBdata),OBwrpy(2,haveOBdata,c),'ko')
    hold on
    %     plot(timer,OBwrpy2(2,:,c),'r.')
    ylabel('y')
    x(3) = subplot(313);
    plot(timer(haveOBdata),OBwrpy(3,haveOBdata,c),'ko')
    hold on
    %     plot(timer,OBwrpy2(3,:,c),'r.')
    ylabel('z')
    xlabel('Time')
    linkaxes(x,'x')
    
    figure(80+c)
    hold on
    title('RPM')
    plot(timer(haveOBdata),OBrpm(1,haveOBdata,c),'r.')
    plot(timer(haveOBdata),OBrpm(2,haveOBdata,c),'g.')
    plot(timer(haveOBdata),OBrpm(3,haveOBdata,c),'b.')
    plot(timer(haveOBdata),OBrpm(4,haveOBdata,c),'y.')
    
    
    figure(90+c)
    x(1) = subplot(311);
    plot(timer(haveOBdata),OBrpy(1,haveOBdata,c),'ko')
    hold on
    plot(timer(haveOBdata),trpySave(2,haveOBdata,c),'r.')
    %     plot(timer,OBwrpy2(1,:,c),'r.')
    title('Onboard RPY')
    ylabel('x')
    x(2) =subplot(312);
    plot(timer(haveOBdata),OBrpy(2,haveOBdata,c),'ko')
    hold on
    plot(timer(haveOBdata),trpySave(3,haveOBdata,c),'g.')
    %     plot(timer,OBwrpy2(2,:,c),'r.')
    ylabel('y')
    x(3) = subplot(313);
    plot(timer(haveOBdata),OBrpy(3,haveOBdata,c),'ko')
    hold on
    %     plot(timer,OBwrpy2(3,:,c),'r.')
    ylabel('z')
    xlabel('Time')
    linkaxes(x,'x')
    
    figure(110+c)
    x(1) = subplot(411);
    plot(timer(haveOBdata),OBacc(1,haveOBdata,c),'ko')
    hold on
    %     plot(timer,OBwrpy2(1,:,c),'r.')
    title('Accelerometer Data')
    ylabel('x')
    x(2) =subplot(412);
    plot(timer(haveOBdata),OBacc(2,haveOBdata,c),'ko')
    hold on
    %     plot(timer,OBwrpy2(2,:,c),'r.')
    ylabel('y')
    x(3) = subplot(413);
    plot(timer(haveOBdata),OBacc(3,haveOBdata,c),'ko')
    hold on
    x(4) = subplot(414);
    plot(timer(haveOBdata),OBcntr(1,haveOBdata,c)/1e4,'r.')
    %     plot(timer,OBwrpy2(3,:,c),'r.')
    ylabel('z')
    xlabel('Time')
    linkaxes(x,'x')
    
    if(0)
        
        figure(110+c)
        x(1) = subplot(411);
        plot(timer(haveOBdata),OBacc(1,haveOBdata,c),'ko')
        hold on
        plot(timer(haveOBdata),OBwrpy(1,haveOBdata,c),'r.')
        %     plot(timer,OBwrpy2(1,:,c),'r.')
        title('Accelerometer Data')
        ylabel('x')
        x(2) =subplot(412);
        plot(timer(haveOBdata),OBacc(2,haveOBdata,c),'ko')
        hold on
        plot(timer(haveOBdata),OBwrpy(2,haveOBdata,c),'r.')
        %     plot(timer,OBwrpy2(2,:,c),'r.')
        ylabel('y')
        x(3) = subplot(413);
        plot(timer(haveOBdata),OBacc(3,haveOBdata,c),'ko')
        hold on
        plot(timer(haveOBdata),OBwrpy(3,haveOBdata,c),'r.')
        x(4) = subplot(414);
        plot(timer(haveOBdata),OBcntr(1,haveOBdata,c)/1e4,'r.')
        %     plot(timer,OBwrpy2(3,:,c),'r.')
        ylabel('z')
        xlabel('Time')
        linkaxes(x,'x')
    end
    
    figure(201)
    hold on
    plot3(DesPosSave(1,:,c),DesPosSave(2,:,c),DesPosSave(3,:,c),colorlist{c})
    hold on
    plot3(ViconData(4,:,c),ViconData(5,:,c),ViconData(6,:,c),'k.')
    axis equal
    grid on
    xlabel('x')
    ylabel('y')
    zlabel('z')
end
