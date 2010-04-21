function result = ipcAPISetMsgQueueLength(msg_name,length)

result = ipcAPI('set_msg_queue_length',msg_name,length);
