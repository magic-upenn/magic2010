%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%receive the Feedback in a standalone script
clear all
close all

addpath('../init')

init_paths

dev  = '/dev/ttyUSB0';
baud = 1000000;
SerialDeviceAPI('connect',dev,baud);

kbeeId = 2;
%SetKbeeMode(kbeeId,1); %receive mode
ch=45;

%packet=DynamixelPacketCreate(5,1,uint8([kbeeId,ch]));
%SerialDeviceAPI('write',packet);

while(1)
    packet = ReceivePacket();

    while(~isempty(packet))
        id   = packet(3);
        type = packet(5);
        
        fprintf('got packet %d %d, length %d\n',id,type,length(packet));
        
        if (id == 0) %LL
            
            if ((type==18) && (length(packet) == 51))
                %Receive the IMU message
                fcntr   = double(typecast(packet(6:9),'uint32'));
                ob_roll    = double(typecast(packet(10:13),'single'));
                ob_pitch   = double(typecast(packet(14:17),'single'));
                ob_yaw   = double(typecast(packet(18:21),'single'));
                ob_wx    = double(typecast(packet(22:25),'single'));
                ob_wy   = double(typecast(packet(26:29),'single'));
                ob_wz    = double(typecast(packet(30:33),'single'));
                ob_ax    = double(typecast(packet(34:37),'single'));
                ob_ay   = double(typecast(packet(38:41),'single'));
                ob_az    = double(typecast(packet(42:45),'single'));
     
            elseif( (type == 18) & length(packet)==27 )
                
                id = double(typecast(packet(6:9),'uint32'));
                temperature = double(typecast(packet(10:13),'single'));
                pressure = double(typecast(packet(14:17),'single'));
                time_baro = double(typecast(packet(18:21),'uint32'));
                  
            elseif (type == 25)
                d.cntr = double(typecast(packet(6:9),'uint32'));
                d.tuc  = double(typecast(packet(10:13),'uint32'));
                d.rpy  = double(typecast(packet(14:25),'single'));
                d.wrpy  = double(typecast(packet(26:37),'single'));
                d.wrpy2  = double(typecast(packet(38:49),'single'));
                d.acc  = double(typecast(packet(50:61),'single'));
                d.rpm = double(typecast(packet(62:69),'uint16'));
                d.id = double(typecast(packet(70),'uint8'));
                d.sig = double(typecast(packet(71),'uint8'));
                d.chan = double(typecast(packet(72),'uint8'));
                d.dummy = double(typecast(packet(73),'uint8'));
                d.voltage = double(typecast(packet(74:77),'single'));
                d.current = double(typecast(packet(78:81),'single'));
                
            end
            
        end
        packet = ReceivePacket();
    end
end