%mdir=getenv('MAGIC_DIR');
%addpath( [ mdir '/ipc' ] )
%addpath( [ mdir '/drivers/Udp'])
%addpath( [ mdir '/Interfaces' ] )
%addpath( [ mdir '/mexSerialization' ] )
%addpath( [ mdir '/components/mexutil'])


addpath( genpath_exclude(getenv('MAGIC_DIR'),'.svn') );
addpath( genpath(getenv('MAGIC_DIR')) )
