function WriteMatResults(ImageData,ARTHRODIR)
if ~isempty(ImageData)
	if isempty(ARTHRODIR)
		[name, directory] = uiputfile('*.mat','Save all the calibration data For further use','CalibData');
        if directory ~= 0
            save(sprintf('%s%s',directory,name),'ImageData');
        end
	else
		save(sprintf('%sCalibData_temp.mat',ARTHRODIR),'ImageData');
        disp(sprintf('Calibration file saved under %sCalibData_temp.mat',ARTHRODIR));
	end
else
    errordlg('No Calibration data to be saved','No Data','modal')
end