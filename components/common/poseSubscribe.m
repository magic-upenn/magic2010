function poseSubscribe
global POSE

poseInit;
ipcAPISubscribe(POSE.msgName);