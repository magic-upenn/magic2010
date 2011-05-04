%% This startup.m is required to ensure that all of your code is
%% correctly on the path. startup.m is run when Matlab is started
%% from this directory.

% Recursively adds anything under the 'code' directory to the path.

fprintf('Adding all subdirectories of current directory to path.\n');
addpath(genpath(pwd)); % To Remove: rmpath(genpath(pwd))


