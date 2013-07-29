function handles = FillWithNull(handles,level,ind);

switch level
    case 1
        handles.ImageData(ind).Info=[];
        handles.ImageData(ind).ImageRGB=[];
        handles.ImageData(ind).Boundary=[];
        handles.ImageData(ind).PosPlaneAuto=[];
        handles.ImageData(ind).PosImageAuto=[];
        handles.ImageData(ind).PosPlane=[];
        handles.ImageData(ind).PosImage=[];
        
        handles.ImageData(ind).InitCalib.qsi = -1;
        handles.ImageData(ind).InitCalib.eta = -1;
        handles.ImageData(ind).InitCalib.focal = -1;
        handles.ImageData(ind).InitCalib.center(1) = -1;
        handles.ImageData(ind).InitCalib.center(2) = -1;
        handles.ImageData(ind).InitCalib.aratio = -1;
        handles.ImageData(ind).InitCalib.skew = -1;
        handles.ImageData(ind).InitCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).InitCalib.T = eye(4);
        
        handles.ImageData(ind).FinalCalib.qsi = -1;
        handles.ImageData(ind).FinalCalib.eta = -1;
        handles.ImageData(ind).FinalCalib.focal = -1;
        handles.ImageData(ind).FinalCalib.center(1) = -1;
        handles.ImageData(ind).FinalCalib.center(2) = -1;
        handles.ImageData(ind).FinalCalib.aratio = -1;
        handles.ImageData(ind).FinalCalib.skew = -1;
        handles.ImageData(ind).FinalCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).FinalCalib.T = eye(4);
        
        handles.ImageData(ind).OptimCalib.qsi = -1;
        handles.ImageData(ind).OptimCalib.eta = -1;
        handles.ImageData(ind).OptimCalib.focal = -1;
        handles.ImageData(ind).OptimCalib.center(1) = -1;
        handles.ImageData(ind).OptimCalib.center(2) = -1;
        handles.ImageData(ind).OptimCalib.aratio = -1;
        handles.ImageData(ind).OptimCalib.skew = -1;
        handles.ImageData(ind).OptimCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).OptimCalib.T = eye(4);
    case 2
        handles.ImageData(ind).Boundary=[];
        handles.ImageData(ind).PosPlaneAuto=[];
        handles.ImageData(ind).PosImageAuto=[];
        handles.ImageData(ind).PosPlane=[];
        handles.ImageData(ind).PosImage=[];
        
        handles.ImageData(ind).InitCalib.qsi = -1;
        handles.ImageData(ind).InitCalib.eta = -1;
        handles.ImageData(ind).InitCalib.focal = -1;
        handles.ImageData(ind).InitCalib.center(1) = -1;
        handles.ImageData(ind).InitCalib.center(2) = -1;
        handles.ImageData(ind).InitCalib.aratio = -1;
        handles.ImageData(ind).InitCalib.skew = -1;
        handles.ImageData(ind).InitCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).InitCalib.T = eye(4);
        
        handles.ImageData(ind).FinalCalib.qsi = -1;
        handles.ImageData(ind).FinalCalib.eta = -1;
        handles.ImageData(ind).FinalCalib.focal = -1;
        handles.ImageData(ind).FinalCalib.center(1) = -1;
        handles.ImageData(ind).FinalCalib.center(2) = -1;
        handles.ImageData(ind).FinalCalib.aratio = -1;
        handles.ImageData(ind).FinalCalib.skew = -1;
        handles.ImageData(ind).FinalCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).FinalCalib.T = eye(4);
        
        handles.ImageData(ind).OptimCalib.qsi = -1;
        handles.ImageData(ind).OptimCalib.eta = -1;
        handles.ImageData(ind).OptimCalib.focal = -1;
        handles.ImageData(ind).OptimCalib.center(1) = -1;
        handles.ImageData(ind).OptimCalib.center(2) = -1;
        handles.ImageData(ind).OptimCalib.aratio = -1;
        handles.ImageData(ind).OptimCalib.skew = -1;
        handles.ImageData(ind).OptimCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).OptimCalib.T = eye(4);
    case 3
        handles.ImageData(ind).PosPlaneAuto=[];
        handles.ImageData(ind).PosImageAuto=[];
        handles.ImageData(ind).PosPlane=[];
        handles.ImageData(ind).PosImage=[];
        
        handles.ImageData(ind).InitCalib.qsi = -1;
        handles.ImageData(ind).InitCalib.eta = -1;
        handles.ImageData(ind).InitCalib.focal = -1;
        handles.ImageData(ind).InitCalib.center(1) = -1;
        handles.ImageData(ind).InitCalib.center(2) = -1;
        handles.ImageData(ind).InitCalib.aratio = -1;
        handles.ImageData(ind).InitCalib.skew = -1;
        handles.ImageData(ind).InitCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).InitCalib.T = eye(4);
        
        handles.ImageData(ind).FinalCalib.qsi = -1;
        handles.ImageData(ind).FinalCalib.eta = -1;
        handles.ImageData(ind).FinalCalib.focal = -1;
        handles.ImageData(ind).FinalCalib.center(1) = -1;
        handles.ImageData(ind).FinalCalib.center(2) = -1;
        handles.ImageData(ind).FinalCalib.aratio = -1;
        handles.ImageData(ind).FinalCalib.skew = -1;
        handles.ImageData(ind).FinalCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).FinalCalib.T = eye(4);
        
        handles.ImageData(ind).OptimCalib.qsi = -1;
        handles.ImageData(ind).OptimCalib.eta = -1;
        handles.ImageData(ind).OptimCalib.focal = -1;
        handles.ImageData(ind).OptimCalib.center(1) = -1;
        handles.ImageData(ind).OptimCalib.center(2) = -1;
        handles.ImageData(ind).OptimCalib.aratio = -1;
        handles.ImageData(ind).OptimCalib.skew = -1;
        handles.ImageData(ind).OptimCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).OptimCalib.T = eye(4);
    case 4
        handles.ImageData(ind).PosPlane=[];
        handles.ImageData(ind).PosImage=[];
        
        handles.ImageData(ind).InitCalib.qsi = -1;
        handles.ImageData(ind).InitCalib.eta = -1;
        handles.ImageData(ind).InitCalib.focal = -1;
        handles.ImageData(ind).InitCalib.center(1) = -1;
        handles.ImageData(ind).InitCalib.center(2) = -1;
        handles.ImageData(ind).InitCalib.aratio = -1;
        handles.ImageData(ind).InitCalib.skew = -1;
        handles.ImageData(ind).InitCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).InitCalib.T = eye(4);
        
        handles.ImageData(ind).FinalCalib.qsi = -1;
        handles.ImageData(ind).FinalCalib.eta = -1;
        handles.ImageData(ind).FinalCalib.focal = -1;
        handles.ImageData(ind).FinalCalib.center(1) = -1;
        handles.ImageData(ind).FinalCalib.center(2) = -1;
        handles.ImageData(ind).FinalCalib.aratio = -1;
        handles.ImageData(ind).FinalCalib.skew = -1;
        handles.ImageData(ind).FinalCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).FinalCalib.T = eye(4);
        
        handles.ImageData(ind).OptimCalib.qsi = -1;
        handles.ImageData(ind).OptimCalib.eta = -1;
        handles.ImageData(ind).OptimCalib.focal = -1;
        handles.ImageData(ind).OptimCalib.center(1) = -1;
        handles.ImageData(ind).OptimCalib.center(2) = -1;
        handles.ImageData(ind).OptimCalib.aratio = -1;
        handles.ImageData(ind).OptimCalib.skew = -1;
        handles.ImageData(ind).OptimCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).OptimCalib.T = eye(4);
    case 5
        handles.ImageData(ind).PosPlane=[];
        handles.ImageData(ind).PosImage=[];

        handles.ImageData(ind).FinalCalib.qsi = -1;
        handles.ImageData(ind).FinalCalib.eta = -1;
        handles.ImageData(ind).FinalCalib.focal = -1;
        handles.ImageData(ind).FinalCalib.center(1) = -1;
        handles.ImageData(ind).FinalCalib.center(2) = -1;
        handles.ImageData(ind).FinalCalib.aratio = -1;
        handles.ImageData(ind).FinalCalib.skew = -1;
        handles.ImageData(ind).FinalCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).FinalCalib.T = eye(4);
        
        handles.ImageData(ind).OptimCalib.qsi = -1;
        handles.ImageData(ind).OptimCalib.eta = -1;
        handles.ImageData(ind).OptimCalib.focal = -1;
        handles.ImageData(ind).OptimCalib.center(1) = -1;
        handles.ImageData(ind).OptimCalib.center(2) = -1;
        handles.ImageData(ind).OptimCalib.aratio = -1;
        handles.ImageData(ind).OptimCalib.skew = -1;
        handles.ImageData(ind).OptimCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).OptimCalib.T = eye(4);
    case 6        
        handles.ImageData(ind).FinalCalib.qsi = -1;
        handles.ImageData(ind).FinalCalib.eta = -1;
        handles.ImageData(ind).FinalCalib.focal = -1;
        handles.ImageData(ind).FinalCalib.center(1) = -1;
        handles.ImageData(ind).FinalCalib.center(2) = -1;
        handles.ImageData(ind).FinalCalib.aratio = -1;
        handles.ImageData(ind).FinalCalib.skew = -1;
        handles.ImageData(ind).FinalCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).FinalCalib.T = eye(4);
        
        handles.ImageData(ind).OptimCalib.qsi = -1;
        handles.ImageData(ind).OptimCalib.eta = -1;
        handles.ImageData(ind).OptimCalib.focal = -1;
        handles.ImageData(ind).OptimCalib.center(1) = -1;
        handles.ImageData(ind).OptimCalib.center(2) = -1;
        handles.ImageData(ind).OptimCalib.aratio = -1;
        handles.ImageData(ind).OptimCalib.skew = -1;
        handles.ImageData(ind).OptimCalib.ReProjError.RMS = -1;
        handles.ImageData(ind).OptimCalib.T = eye(4);
end
