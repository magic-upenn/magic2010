%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function result = ipcAPIPublishVC(msg_name,msg)

result = ipcAPI('publishVC',msg_name,msg);
