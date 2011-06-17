addpath( [ getenv('VIS_DIR') '/ipc' ] )
addpath( [ getenv('VIS_DIR') '/Interfaces' ] )
addpath( [ getenv('VIS_DIR') '/mexSerialization' ] )


addpath( genpath_exclude(getenv('MAGIC_DIR'),'.svn') );
%addpath( genpath(getenv('MAGIC_DIR')) )