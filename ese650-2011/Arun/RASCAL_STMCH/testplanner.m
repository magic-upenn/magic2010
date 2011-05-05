%addStateMchpaths;
clear all
close all
%addpath('/home/ese650/svn/magic2010/ese650-2011/Arun/');
%addpath('/home/ese650/svn/magic2010/ese650-2011/Arun/RASCAL_STMCH/');
%A = load('Lidardata_01-May-2011_22:14:03.mat');
A = load('test.mat');
B = A.MAP.map;
B(B == 0) = 1;
%B = conv2(double(B),ones(11),'same');

tic
[C,ind] = plannerAstar(double(B),[206 328],[309 348]);
toc

figure;imagesc(B);colormap gray;
hold on
plot(C(2,1:ind),C(1,1:ind),'r.');