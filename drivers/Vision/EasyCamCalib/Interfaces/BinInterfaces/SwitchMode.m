function SwitchMode(hObject, eventdata, handles)


if ~handles.LISTMODE % For image Mode
    set(handles.pushbutton_adddir,'enable','on');
    set(handles.text_path,'enable','on');
    set(handles.pushbutton_clearlist,'enable','on');
    set(handles.pushbutton_adddir,'enable','on');
    set(handles.pushbutton_removeimage,'enable','on');
    set(handles.pushbutton_addimage,'enable','on');
    set(handles.dirlist,'enable','on');
    set(handles.switch_to,'String','Load Data');
    set(handles.radiobutton_showinit,'enable','off');
    set(handles.radiobutton_showfinal,'enable','off');
    set(handles.radiobutton_showoptim,'enable','off');
    set(handles.switch_coordinates,'enable','off');
    set(handles.switch_autocorners,'enable','off');
    set(handles.switch_boundary,'enable','off');
    set(handles.switch_finalcalib,'enable','off');
    set(handles.switch_initcalib,'enable','off');
    set(handles.switch_optimcalib,'enable','off');
    set(handles.switch_blamepoints,'enable','off');
    set(handles.switch_to,'BackgroundColor',[0.7, 0.7, 0.7]);
    set(handles.pushbutton_start,'BackgroundColor',[0 127 0]./255);
else % For data mode
    set(handles.pushbutton_adddir,'enable','off');
    set(handles.text_path,'enable','off');
    set(handles.pushbutton_clearlist,'enable','on');
    set(handles.pushbutton_adddir,'enable','off');
    set(handles.pushbutton_removeimage,'enable','off');
    set(handles.pushbutton_addimage,'enable','off');
    set(handles.dirlist,'enable','off');
    set(handles.switch_to,'String','Return');
    set(handles.figure1,'SelectionType','normal');
    set(handles.tocalibrate,'Value',1);
    set(handles.radiobutton_showinit,'enable','on');
    set(handles.radiobutton_showfinal,'enable','on');
    set(handles.switch_coordinates,'enable','on');
    set(handles.switch_autocorners,'enable','on');
    if isfield(handles.ImageData(1).Boundary,'Omega')
        set(handles.switch_boundary,'enable','on');
    end
    set(handles.switch_finalcalib,'enable','on');
    set(handles.switch_initcalib,'enable','on');
    if isfield(handles.ImageData(1),'OptimCalib')
        set(handles.switch_optimcalib,'enable','on');
        set(handles.radiobutton_showoptim,'enable','on');
    end
    set(handles.switch_blamepoints,'enable','on');
    set(handles.switch_to,'BackgroundColor',[25 173 0]./255);
    set(handles.pushbutton_start,'BackgroundColor',[0.7, 0.7, 0.7]);
end
guidata(hObject, handles);