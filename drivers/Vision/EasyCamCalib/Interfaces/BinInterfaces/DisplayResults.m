function DisplayResults(handles,i,opt)

auxstruct = [];
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

eta = auxstruct.eta;
focal = auxstruct.focal;
aratio = auxstruct.aratio;
skew = auxstruct.skew;
center = auxstruct.center;
qsi = auxstruct.qsi;
angle =  rad2deg(acos(dot(-auxstruct.T(1:3,3),[0;0;1])));
distance =  norm(auxstruct.T(1:3,4));
if isfield(auxstruct,'qsi0')
    set(handles.text_qsi0, 'Visible', 'on');
    set(handles.text_qsi0, 'String',auxstruct.qsi0);
else
    set(handles.text_qsi0, 'Visible', 'off');
end
set(handles.text_eta, 'String',eta);
set(handles.text_aratio, 'String',aratio);
set(handles.text_skew, 'String',skew);
set(handles.text_center,'String',sprintf('(%.1f , %.1f)',center(1),center(2)));
set(handles.text_focal, 'String',focal);
set(handles.text_qsi, 'String',qsi);
set(handles.angle, 'String',sprintf('%.1fº',angle));
set(handles.distance, 'String',sprintf('%.1fmm',distance));
drawnow
