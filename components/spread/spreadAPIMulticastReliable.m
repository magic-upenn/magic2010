function y = spreadAPIMulticastReliable(group, data, mess_type);

service_type = 2; % RELIABLE_MESS

if nargin < 3,
  mess_type = 0;
end
  
y = spreadAPI('multicast',service_type,group,mess_type,data);
