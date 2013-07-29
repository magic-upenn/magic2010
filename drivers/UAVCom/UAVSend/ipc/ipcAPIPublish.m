%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function result = ipcAPIPublish(msg_name,msg);

result = ipcAPI('publish',msg_name,msg);
