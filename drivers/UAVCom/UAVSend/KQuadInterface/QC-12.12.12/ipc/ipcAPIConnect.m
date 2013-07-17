%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function result = ipcAPIConnect(hostname)

if nargin < 1,
  hostname = 'localhost'; % Default hostname
end

result = ipcAPI('connect',hostname);
