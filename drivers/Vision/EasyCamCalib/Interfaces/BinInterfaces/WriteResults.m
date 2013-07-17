function WriteResults (opt,handles)

switch opt
    case 0 %Calibration
        file = sprintf('%sCalibration.txt',handles.dirtosavecalib);
        disp(sprintf('Writing Results to %s',file))
        fid = fopen(file,'wt');
        if (fid < 0)
            disp('WARNING!!! could not open file 0');
            return
        end
        if handles.REFINEMENT
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.eta);
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.qsi);
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.aratio);
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.skew);
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.center(1));
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.center(2));
            fprintf(fid,'%f',handles.ImageData(1).OptimCalib.focal);
        else
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.eta);
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.qsi);
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.aratio);
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.skew);
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.center(1));
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.center(2));
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.focal);
        end
        fprintf(fid,'%f ',handles.ImageData(1).Boundary.LensAngle);
        fprintf(fid,'%f ',handles.ImageData(1).Boundary.LensAngleImage(1));
        fprintf(fid,'%f ',handles.ImageData(1).Boundary.LensAngleImage(2));
        fprintf(fid,'%f ',(handles.ImageData(1).Boundary.Parameters.B+handles.ImageData(1).Boundary.Parameters.A)/2);
        fprintf(fid,'%f ',handles.ImageData(1).Boundary.Parameters.Center(1));
        fprintf(fid,'%f',handles.ImageData(1).Boundary.Parameters.Center(2));

    case 1 %HandEye
        file = sprintf('%sHandEye.txt',handles.dirtosavecalib);
        disp(sprintf('Writing Results to %s',file))
        fid = fopen(file,'wt');
        if (fid < 0)
            disp('WARNING!!! could not open file 1');
            return
        end
        if handles.REFINEMENT
            fprintf(fid,'%f ',handles.ImageData(1).HE.OptimCalib(1,1));
            fprintf(fid,'%f ',handles.ImageData(1).HE.OptimCalib(1,2));
            fprintf(fid,'%f ',handles.ImageData(1).HE.OptimCalib(1,3));
            fprintf(fid,'%f ',handles.ImageData(1).HE.OptimCalib(2,1));
            fprintf(fid,'%f ',handles.ImageData(1).HE.OptimCalib(2,2));
            fprintf(fid,'%f ',handles.ImageData(1).HE.OptimCalib(2,3));
            fprintf(fid,'%f ',handles.ImageData(1).HE.OptimCalib(3,1));
            fprintf(fid,'%f ',handles.ImageData(1).HE.OptimCalib(3,2));
            fprintf(fid,'%f ',handles.ImageData(1).HE.OptimCalib(3,3));
            fprintf(fid,'%f ',handles.ImageData(1).HE.OptimCalib(1,4));
            fprintf(fid,'%f ',handles.ImageData(1).HE.OptimCalib(2,4));
            fprintf(fid,'%f',handles.ImageData(1).HE.OptimCalib(3,4));
        else
            fprintf(fid,'%f ',handles.ImageData(1).HE.FinalCalib(1,1));
            fprintf(fid,'%f ',handles.ImageData(1).HE.FinalCalib(1,2));
            fprintf(fid,'%f ',handles.ImageData(1).HE.FinalCalib(1,3));
            fprintf(fid,'%f ',handles.ImageData(1).HE.FinalCalib(2,1));
            fprintf(fid,'%f ',handles.ImageData(1).HE.FinalCalib(2,2));
            fprintf(fid,'%f ',handles.ImageData(1).HE.FinalCalib(2,3));
            fprintf(fid,'%f ',handles.ImageData(1).HE.FinalCalib(3,1));
            fprintf(fid,'%f ',handles.ImageData(1).HE.FinalCalib(3,2));
            fprintf(fid,'%f ',handles.ImageData(1).HE.FinalCalib(3,3));
            fprintf(fid,'%f ',handles.ImageData(1).HE.FinalCalib(1,4));
            fprintf(fid,'%f ',handles.ImageData(1).HE.FinalCalib(2,4));
            fprintf(fid,'%f',handles.ImageData(1).HE.FinalCalib(3,4));
        end
        
    case 2 %Arthroscope first position
        file = sprintf('%sArthroPos1.txt',handles.dirtosavecalib);
        disp(sprintf('Writing Results to %s',file))
        fid = fopen(file,'wt');
        if (fid < 0)
            disp('WARNING!!! could not open file 2');
            return
        end
        if (isfield(handles.ImageData,'Hand2Opto'))
            fprintf(fid,'%f ',handles.ImageData(1).Hand2Opto(1,1));
            fprintf(fid,'%f ',handles.ImageData(1).Hand2Opto(1,2));
            fprintf(fid,'%f ',handles.ImageData(1).Hand2Opto(1,3));
            fprintf(fid,'%f ',handles.ImageData(1).Hand2Opto(2,1));
            fprintf(fid,'%f ',handles.ImageData(1).Hand2Opto(2,2));
            fprintf(fid,'%f ',handles.ImageData(1).Hand2Opto(2,3));
            fprintf(fid,'%f ',handles.ImageData(1).Hand2Opto(3,1));
            fprintf(fid,'%f ',handles.ImageData(1).Hand2Opto(3,2));
            fprintf(fid,'%f ',handles.ImageData(1).Hand2Opto(3,3));
            fprintf(fid,'%f ',handles.ImageData(1).Hand2Opto(1,4));
            fprintf(fid,'%f ',handles.ImageData(1).Hand2Opto(2,4));
            fprintf(fid,'%f',handles.ImageData(1).Hand2Opto(3,4));
        end
    
    case 3 %Extrinsics for position 1
        file = sprintf('%sExtrinsics.txt',handles.dirtosavecalib);
        disp(sprintf('Writing Results to %s',file))
        fid = fopen(file,'wt');
        if (fid < 0)
            disp('WARNING!!! could not open file 3');
            return
        end
        if handles.REFINEMENT
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.T(1,1));
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.T(1,2));
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.T(1,3));
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.T(2,1));
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.T(2,2));
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.T(2,3));
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.T(3,1));
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.T(3,2));
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.T(3,3));
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.T(1));
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.T(2));
            fprintf(fid,'%f',handles.ImageData(1).OptimCalib.T(3));
        else
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.T(1,1));
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.T(1,2));
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.T(1,3));
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.T(2,1));
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.T(2,2));
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.T(2,3));
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.T(3,1));
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.T(3,2));
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.T(3,3));
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.T(1,4));
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.T(2,4));
            fprintf(fid,'%f',handles.ImageData(1).FinalCalib.T(3,4));
        end
    case 4 %Calibration from menu
        disp(sprintf('Writing Results to %s',handles.dirtosavecalib))
        fid = fopen(handles.dirtosavecalib,'wt');
        if (fid < 0)
            disp('WARNING!!! could not open file 0');
            return
        end
        if handles.REFINEMENT
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.eta);
            if (isfield(handles.ImageData(1).OptimCalib,'qsi0'))
                fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.qsi0);
            end
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.qsi);
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.aratio);
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.skew);
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.center(1));
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.center(2));
            fprintf(fid,'%f ',handles.ImageData(1).OptimCalib.focal);
        else
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.eta);
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.qsi);
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.aratio);
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.skew);
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.center(1));
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.center(2));
            fprintf(fid,'%f ',handles.ImageData(1).FinalCalib.focal);
        end
        if ~isempty(handles.ImageData(1).Boundary)
            fprintf(fid,'%f ',handles.ImageData(1).Boundary.LensAngle);
            fprintf(fid,'%f ',handles.ImageData(1).Boundary.LensAngleImage(1));
            fprintf(fid,'%f ',handles.ImageData(1).Boundary.LensAngleImage(2));
            fprintf(fid,'%f ',(handles.ImageData(1).Boundary.Parameters.B+handles.ImageData(1).Boundary.Parameters.A)/2);
            fprintf(fid,'%f ',handles.ImageData(1).Boundary.Parameters.Center(1));
            fprintf(fid,'%f',handles.ImageData(1).Boundary.Parameters.Center(2));
        else
            fprintf(fid,'%f ',0);
            fprintf(fid,'%f ',0);
            fprintf(fid,'%f ',0);
            fprintf(fid,'%f ',0);
            fprintf(fid,'%f ',0);
            fprintf(fid,'%f',0);
        end
    otherwise
        disp('Unrecognise write option')
        
end