%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function ReceiveQuadDebug2()
clear all;
close all;

addpath ../../api
dev  = '/dev/ttyUSB0';
baud = 1000000;
SerialDeviceAPI('connect',dev,baud);


while(1)
  %fprintf('.');
  packet = ReceivePacket();
  if ~isempty(packet)
    id   = packet(3);
    type = packet(5);
    
    len  = length(packet);
    
    fprintf('got packet %d %d of length %d\n',id,type,len);
    
    
    if (id == 0 && type == 28)
      d.cntr    = double(typecast(packet(6),'uint8'));
      d.id      = double(typecast(packet(7),'uint8'));
      d.trpy    = double(typecast(packet(8:15),'int16'))*0.001;
      d.voltage = double(typecast(packet(16:17),'uint16'))*0.01;
      d.sig     = double(typecast(packet(18),'uint8'));
      d.nerr    = double(typecast(packet(19),'uint8'));
      d.chan    = double(typecast(packet(20),'uint8'));
      d
      
    elseif (id == 5 && type == 3) %rx status
      st.t    = typecast(packet(6:9),'uint32');
      st.err  = typecast(packet(10:13),'uint32');
      st.id   = typecast(packet(14),'uint8');
      st.len  = typecast(packet(15),'uint8');
      st.lqi  = typecast(packet(16),'uint8');
      st.ed   = typecast(packet(17),'uint8');
      st.st   = typecast(packet(18),'uint8');
      st.chan = typecast(packet(19),'uint8');
      
      st
      
    end
   
       
  end
  
end