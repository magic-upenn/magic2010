%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function result = ipcAPISetMsgQueueLength(msg_name,length)

result = ipcAPI('set_msg_queue_length',msg_name,length);
