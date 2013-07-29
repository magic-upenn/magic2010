function outstruct = DefineOriginsSingleMarkManualAutoCalibGUI(ImageData)
[dummy,N]=size(ImageData);


%% Change the origins
cancel = 0;
for i=1:1:N
    [T_new PosPlaneNew cancel] = DefineOriginManual(ImageData(i));
    ImageData(i).FinalCalib.T = T_new;
    ImageData(i).PosPlane = PosPlaneNew;
    if cancel
        break
    end
end

outstruct = ImageData;