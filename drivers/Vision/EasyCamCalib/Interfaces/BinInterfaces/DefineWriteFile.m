function DefineWriteFile (defaultdir)

if defaultdir
    if isempty(DefaultDir)
        [DefaultName, DefaultDir] = uiputfile('*.txt','Select results directory and default file name','CalibParameters');
    end  
end