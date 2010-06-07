global SPREAD

if isempty(SPREAD),
  [SPREAD.mbox, SPREAD.private_group] = spreadAPIConnect('4803');
end
  
spreadAPIJoin('TEST');

spreadAPIMulticastFIFO('TEST',uint8('hello there'));

m = spreadAPIReceive
while ~isempty(m),
  disp(sprintf('Message received: %s', char(m.message)));
  m = spreadAPIReceive;
end

%spreadAPIDisconnect;
