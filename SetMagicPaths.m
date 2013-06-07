addpath( [ getenv('MAGIC_DIR') '/ipc' ] )
addpath( [ getenv('MAGIC_DIR') '/Interfaces' ] )
addpath( [ getenv('MAGIC_DIR') '/mexSerialization' ] )


addpath( genpath_exclude(getenv('MAGIC_DIR'),'.svn') );
%addpath( genpath(getenv('MAGIC_DIR')) )
