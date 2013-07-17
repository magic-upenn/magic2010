%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function result = ipcAPISubscribe(msg_name)

result = ipcAPI('subscribe', msg_name);
