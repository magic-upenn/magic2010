function y = spreadSendUnreliable(name, data);

persistent hostname

if isempty(hostname),
  hostname = gethostname;
end

group = [hostname '/' name];
service_type = 1; % UNRELIABLE_MESS
mess_type = 0;
  
y = spreadAPI('multicast',service_type,group,mess_type,data);
