%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function ReceiveQuadDebug1()
clear all;
close all;

addpath ../../api
dev  = '/dev/ttyUSB1';
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