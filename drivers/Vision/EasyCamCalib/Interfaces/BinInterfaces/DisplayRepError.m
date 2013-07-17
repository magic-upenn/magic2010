function DisplayRepError(handles,opt,type)

auxstruct = [];
acc = [];
if(type==1)
    set(handles.repbar,'Visible','off');
    if(handles.barhandler)
       set(handles.barhandler,'Visible','off'); 
    end
    for i=1:20
        set(eval(sprintf('handles.rep%d',i)),'Visible','on');
    end
    for i=1:length(handles.ImageData)
        switch opt
            case 0
                auxstruct = handles.ImageData(i).InitCalib;
                set(handles.radiobutton_showinit,'Value',1);
            case 1
                auxstruct = handles.ImageData(i).FinalCalib;
                set(handles.radiobutton_showfinal,'Value',1);
            case 2
                auxstruct = handles.ImageData(i).OptimCalib;
                set(handles.radiobutton_showoptim,'Value',1);
        end
        try
            set(eval(sprintf('handles.rep%d',i)),'String',auxstruct.ReProjError.RMS);
        catch
        end
        acc = [acc auxstruct.ReProjError.RMS];
    end
    
    for i=length(handles.ImageData)+1:20
        set(eval(sprintf('handles.rep%d',i)),'String','');
    end
end
if(type==0)
    set(handles.repbar,'Visible','on');
    for i=1:20
        set(eval(sprintf('handles.rep%d',i)),'Visible','off');
    end
    for i=1:length(handles.ImageData)
        switch opt
            case 0
                auxstruct = handles.ImageData(i).InitCalib;
                set(handles.radiobutton_showinit,'Value',1);
            case 1
                auxstruct = handles.ImageData(i).FinalCalib;
                set(handles.radiobutton_showfinal,'Value',1);
            case 2
                auxstruct = handles.ImageData(i).OptimCalib;
                set(handles.radiobutton_showoptim,'Value',1);
        end
        acc = [acc auxstruct.ReProjError.RMS];
    end
    axes(handles.repbar);
    if(~isempty(acc))
        handles.barhandler=bar(acc);
        set(handles.barhandler,'Visible','on','EdgeColor','b','FaceColor',[123 33 200]./255);
    end
end

meanrms = mean(acc);
set(handles.meanrms,'String',meanrms);  
guidata(handles.figure1,handles)
drawnow