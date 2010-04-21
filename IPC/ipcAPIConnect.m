function result = ipcAPIConnect(hostname)

if nargin < 1,
  hostname = 'localhost'; % Default hostname
end

result = ipcAPI('connect',hostname);
