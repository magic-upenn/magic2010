function [mbox, private_group] = spreadAPIConnect(proc_name,private_name,priority,group_membership);

if nargin < 1,
  proc_name = '4803'; % Default port number
end
if nargin < 2,
  private_name = '';
end
if nargin < 3,
  priority = 0;
end
if nargin < 4,
  group_membership = 0;
end

[mbox, private_group] = spreadAPI('connect',...
				  proc_name,private_name,priority,group_membership);
