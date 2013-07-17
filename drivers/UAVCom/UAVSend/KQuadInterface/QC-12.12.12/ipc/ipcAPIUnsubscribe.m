%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function result = ipcAPIUnsubscribe(msg_name)

result = ipcAPI('unsubscribe', msg_name);
