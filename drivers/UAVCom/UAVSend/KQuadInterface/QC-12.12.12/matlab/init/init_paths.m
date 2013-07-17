%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%init_paths

QCdir = getenv('QC_ROOT_PATH');

addpath(strcat(QCdir,'/matlab/control'))
addpath(strcat(QCdir,'/matlab/ipcmsg'))
addpath(strcat(QCdir,'/matlab/plotting'))
addpath(strcat(QCdir,'/matlab/utils'))
addpath(strcat(QCdir,'/matlab/control'))
addpath(strcat(QCdir,'/matlab/control/controllers'))
addpath(strcat(QCdir,'/matlab/algs'))
addpath(strcat(QCdir,'/matlab/feedback'))
addpath(strcat(QCdir,'/matlab/position'))
addpath(strcat(QCdir,'/matlab/calibData'))
addpath(strcat(QCdir,'/matlab/vicon'))
addpath(strcat(QCdir,'/ipc'))
addpath(strcat(QCdir,'/api'))

addpath(strcat(QCdir,'/drivers/ViconNew'))
addpath(strcat(QCdir,'/drivers/DynamixelPacket'))
addpath(strcat(QCdir,'/interfaces/kQuadIface-09.01.12/'))

% addpath('/home/dmel/svn/kmel2/trunk/QC/interfaces/kQuadIface-02.15.12')