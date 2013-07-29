%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%populate all the data for all the quads in the experiment

for c=1:nquad
    switch qd{c}.id
        case 1
            qd{c}.type = 1;
            qd{c}.name = 'Quad1';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 1;
            qd{c}.kbeeid = 101;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 2
            qd{c}.type = 1;
            qd{c}.name = 'Quad2';
            qd{c}.kbeechannel = 2;
            qd{c}.kbeeid = 102;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 3
            qd{c}.type = 1;
            qd{c}.name = 'Quad3';
            qd{c}.kbeechannel = 3;
            qd{c}.kbeeid = 103;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 4
            qd{c}.type = 1;
            qd{c}.name = 'Quad4';
            qd{c}.kbeechannel = 4;
            qd{c}.kbeeid = 104;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 101
            qd{c}.type = 1;
            qd{c}.calib = 'Nano1Calib.mat';
            qd{c}.name = 'Nano1';
            qd{c}.kbeechannel = 1;
            qd{c}.kbeeid = 1;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 103
            qd{c}.type = 1;
            qd{c}.calib = 'Nano3Calib.mat';
            qd{c}.name = 'Nano3';
            qd{c}.kbeechannel = 2;
            qd{c}.kbeeid = 2;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 104
            qd{c}.type = 1;
            qd{c}.calib = 'Nano4Calib.mat';
            qd{c}.name = 'Nano4';
            qd{c}.kbeechannel =2;
            qd{c}.kbeeid = 2;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 105
            qd{c}.type = 1;
            qd{c}.calib = 'Nano5Calib.mat';
            qd{c}.kbeechannel = 3;
            qd{c}.kbeeid = 3;
            qd{c}.name = 'Nano5';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 106
            qd{c}.type = 1;
            qd{c}.calib = 'Nano6Calib.mat';
            qd{c}.kbeechannel = 4;
            qd{c}.kbeeid = 4;
            qd{c}.name = 'Nano6';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 107
            qd{c}.type = 1;
            qd{c}.calib = 'Nano7Calib.mat';
            qd{c}.kbeechannel = 5;
            qd{c}.kbeeid = 5;
            qd{c}.name = 'Nano7';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 108
            qd{c}.type = 1;
            qd{c}.calib = 'Nano8Calib.mat';
            qd{c}.kbeechannel = 21;
            qd{c}.kbeeid = 11;
            qd{c}.name = 'Nano8';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 109
            qd{c}.type = 1;
            qd{c}.calib = 'Nano9Calib.mat';
            qd{c}.kbeechannel = 7;
            qd{c}.kbeeid = 7;
            qd{c}.name = 'Nano9';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 110
            qd{c}.type = 1;
            qd{c}.calib = 'Nano10Calib.mat';
            qd{c}.kbeechannel = 24;
            qd{c}.kbeeid = 14;
            qd{c}.name = 'Nano10';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 111
            qd{c}.type = 1;
            qd{c}.calib = 'Nano11Calib.mat';
            qd{c}.kbeechannel = 10;
            qd{c}.kbeeid = 10;
            qd{c}.name = 'Nano11';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 112
            qd{c}.type = 1;
            qd{c}.calib = 'Nano12Calib.mat';
            qd{c}.kbeechannel = 8;
            qd{c}.kbeeid = 8;
            qd{c}.name = 'Nano12';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 113
            qd{c}.type = 1;
            qd{c}.calib = 'Nano13Calib.mat';
            qd{c}.kbeechannel = 6;
            qd{c}.kbeeid = 6;
            qd{c}.name = 'Nano13';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 114
            qd{c}.type = 1;
            qd{c}.calib = 'Nano14Calib.mat';
            qd{c}.kbeechannel = 9;
            qd{c}.kbeeid = 9;
            qd{c}.name = 'Nano14';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 115
            qd{c}.type = 1;
            qd{c}.calib = 'Nano15Calib.mat';
            qd{c}.kbeechannel = 22;
            qd{c}.kbeeid = 12;
            qd{c}.name = 'Nano15';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 116
            qd{c}.type = 1;
            qd{c}.calib = 'Nano16Calib.mat';
            qd{c}.kbeechannel = 27;
            qd{c}.kbeeid = 19;
            qd{c}.name = 'Nano16';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 117
            qd{c}.type = 1;
            qd{c}.calib = 'Nano17Calib.mat';
            qd{c}.kbeechannel = 27;
            qd{c}.kbeeid = 17;
            qd{c}.name = 'Nano17';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 119
            qd{c}.type = 1;
            qd{c}.calib = 'Nano19Calib.mat';
            qd{c}.kbeechannel = 25;
            qd{c}.kbeeid = 15;
            qd{c}.name = 'Nano19';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 120
            qd{c}.type = 1;
            qd{c}.calib = 'Nano20Calib.mat';
            qd{c}.kbeechannel = 23;
            qd{c}.kbeeid = 13;
            qd{c}.name = 'Nano20';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 121
            qd{c}.type = 1;
            qd{c}.calib = 'Nano21Calib.mat';
            qd{c}.kbeechannel = 26;
            qd{c}.kbeeid = 16;
            qd{c}.name = 'Nano21';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 122
            qd{c}.type = 1;
            qd{c}.calib = 'Nano22Calib.mat';
            qd{c}.kbeechannel = 1;
            qd{c}.kbeeid = 1;
            qd{c}.name = 'Nano22';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 123
            qd{c}.type = 1;
            qd{c}.calib = 'Nano23Calib.mat';
            qd{c}.kbeechannel = 38;
            qd{c}.kbeeid = 18;
            qd{c}.name = 'Nano23';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 124
            qd{c}.type = 1;
            qd{c}.calib = 'Nano24Calib.mat';
            qd{c}.kbeechannel = 38;
            qd{c}.kbeeid = 20;
            qd{c}.name = 'Nano24';
            qd{c}.driver = @kQuadInterfaceAPI;
        case 501
            qd{c}.type = 5;
            qd{c}.name = 'NDS1';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 15;
            qd{c}.kbeeid = 115;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 503
            qd{c}.type = 5;
            qd{c}.name = 'NDS3';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 3;
            qd{c}.kbeeid = 103;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 504
            qd{c}.type = 5;
            qd{c}.name = 'NDS4';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 11;
            qd{c}.kbeeid = 111;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 505
            qd{c}.type = 5;
            qd{c}.name = 'NDS5';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 19;
            qd{c}.kbeeid = 119;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 506
            qd{c}.type = 5;
            qd{c}.name = 'NDS6';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 23;
            qd{c}.kbeeid = 123;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 507
            qd{c}.type = 5;
            qd{c}.name = 'NDS7';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 1;
            qd{c}.kbeeid = 101;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 508
            qd{c}.type = 5;
            qd{c}.name = 'NDS8';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 40;
            qd{c}.kbeeid = 140;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 509
            qd{c}.type = 5;
            qd{c}.name = 'NDS9';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 31;
            qd{c}.kbeeid = 131;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 510
            qd{c}.type = 5;
            qd{c}.name = 'NDS10';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 7;
            qd{c}.kbeeid = 107;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 512
            qd{c}.type = 5;
            qd{c}.name = 'NDS12';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 27;
            qd{c}.kbeeid = 127;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 513
            qd{c}.type = 5;
            qd{c}.name = 'NDS13';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 17;
            qd{c}.kbeeid = 117;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 514
            qd{c}.type = 5;
            qd{c}.name = 'NDS14';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 25;
            qd{c}.kbeeid = 125;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 515
            qd{c}.type = 5;
            qd{c}.name = 'NDS15';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 39;
            qd{c}.kbeeid = 139;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 516
            qd{c}.type = 5;
            qd{c}.name = 'NDS16';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 13;
            qd{c}.kbeeid = 113;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 517
            qd{c}.type = 5;
            qd{c}.name = 'NDS17';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 33;
            qd{c}.kbeeid = 133;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 518
            qd{c}.type = 5;
            qd{c}.name = 'NDS18';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 37;
            qd{c}.kbeeid = 137;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 520
            qd{c}.type = 5;
            qd{c}.name = 'NDS20';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 9;
            qd{c}.kbeeid = 109;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 521
            qd{c}.type = 5;
            qd{c}.name = 'NDS21';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 21;
            qd{c}.kbeeid = 121;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 522
            qd{c}.type = 5;
            qd{c}.name = 'NDS22';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 29;
            qd{c}.kbeeid = 129;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 523
            qd{c}.type = 5;
            qd{c}.name = 'NDS23';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 1;
            qd{c}.kbeeid = 1;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 524
            qd{c}.type = 5;
            qd{c}.name = 'NDS24';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 1;
            qd{c}.kbeeid = 1;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 601
            qd{c}.type = 6;
            qd{c}.name = 'Mega1';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 40;
            qd{c}.kbeeid = 140;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 702
            qd{c}.type = 7;
            qd{c}.name = 'NewNano2';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 1;
            qd{c}.kbeeid = 1;
            qd{c}.driver = @kQuadInterfaceAPI;
        case 703
            qd{c}.type = 7;
            qd{c}.name = 'NewNano3';
            qd{c}.calib = strcat(qd{c}.name,'Calib.mat');
            qd{c}.kbeechannel = 1;
            qd{c}.kbeeid = 1;
            qd{c}.driver = @kQuadInterfaceAPI;
    end
    
    load(qd{c}.calib);
    qd{c}.QuadB_R_QuadBVM = QuadB_R_QuadBV;
    qd{c}.T_rel_BVM = T_rel_BV;
end