%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
if(get_feedback)
    packet = ReceivePacket();

    while(~isempty(packet))
        id   = packet(3);
        type = packet(5);
        
%         fprintf('got packet %d %d, length %d\n',id,type,length(packet));
        
        if (id == 0 && type == 25)
            d.cntr    = double(typecast(packet(6:9),'uint32'));
            d.tuc     = double(typecast(packet(10:13),'uint32'));
            d.rpy     = double(typecast(packet(14:25),'single'));
            d.wrpy    = double(typecast(packet(26:37),'single'));
            d.wrpy2   = double(typecast(packet(38:49),'single'));
            d.acc     = double(typecast(packet(50:61),'single'));
            d.rpm     = double(typecast(packet(62:69),'uint16'));
            d.id      = double(typecast(packet(70),'uint8'));
            d.sig     = double(typecast(packet(71),'uint8'));
            d.chan    = double(typecast(packet(72),'uint8'));
            d.dummy   = double(typecast(packet(73),'uint8'));
            d.voltage = double(typecast(packet(74:77),'single'));
            d.current = double(typecast(packet(78:81),'single'));
            
            OBrpy(:,j,1) = d.rpy';
            OBwrpy(:,j,1) = d.wrpy';
            OBwrpy2(:,j,1) = d.wrpy2';
            OBacc(:,j,1) = d.acc';
            OBrpm(:,j,1) = d.rpm';
            OBvoltage(:,j,1) = d.voltage;
            OBcurrent(:,j,1) = d.current;
            
%             if(mod(j,10)==0)
%                 fprintf('voltage: %f\n',d.voltage')
%             end
            d;
  
        elseif (id == 0 && type == 28)
            d.cntr    = double(typecast(packet(6),'uint8'));
            d.id      = double(typecast(packet(7),'uint8'));
            d.trpy    = double(typecast(packet(8:15),'int16'))*0.001;
            d.voltage = double(typecast(packet(16:17),'uint16'))*0.01;
            d.sig     = double(typecast(packet(18),'uint8'));
            d.nerr    = double(typecast(packet(19),'uint8'));
            d.chan    = double(typecast(packet(20),'uint8'));
            d;
            
            OBrpy(:,j,1) = d.trpy(2:4)';
            OBvoltage(:,j,1) = d.voltage;
            
            if(mod(j,10)==0)
                fprintf('voltage: %f\n',d.voltage')
            end
            
        elseif (id == 5 && type == 3) %rx status
            st.t   = typecast(packet(6:9),'uint32');
            st.id  = typecast(packet(10),'uint8');
            st.len = typecast(packet(11),'uint8');
            st.lqi = typecast(packet(12),'uint8');
            st.ed  = typecast(packet(13),'uint8');
            st.st  = typecast(packet(14),'uint8');
            
            st;
            
        end
        
        packet = ReceivePacket();
    end
end