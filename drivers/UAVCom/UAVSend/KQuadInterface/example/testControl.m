clear all

addpath '../QC-12.12.12/api'
addpath '../QC-12.12.12'
addpath '../QC-12.12.12/matlab/utils'
addpath '../QC-12.12.12/interfaces/kQuadIface-12.12.12'

qcontrol=@kQuadInterfaceAPI
qcontrol('connect','/dev/ttyUSB0',1000000)
qcontrol('SendQuadCmd1',