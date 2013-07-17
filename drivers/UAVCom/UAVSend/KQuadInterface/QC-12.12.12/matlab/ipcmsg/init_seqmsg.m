%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
QCdir = getenv('QC_ROOT_PATH');

addpath(strcat(QCdir,'/matlab/seq'))
addpath(strcat(QCdir,'/ipc'))
addpath(strcat(QCdir,'/matlab/utils'))

ipcAPIConnect();

msg_name = 'seqmsg';

ipcAPIDefine(msg_name);
ipcAPIDefine(msg_name); %re-definition does not hurt
ipcAPISubscribe(msg_name);

yawdes = 0;

t_inf = 10000000;
numquads = 4;
clear seq