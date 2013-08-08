%addpath( [ getenv('MAGIC_DIR') '/ipc' ] )
addpath( [ getenv('MAGIC_DIR') '/ipc' ] )
%addpath( [ getenv('MAGIC_DIR') '/Interfaces' ] )
%addpath( [ getenv('MAGIC_DIR') '/mexSerialization' ] )


%addpath( genpath_exclude(getenv('MAGIC_DIR'),'.svn') );
%If you get errors such as 'Non-existant directory: /ipc' - Uncomment next line
%addpath( genpath(getenv('MAGIC_DIR')) )
