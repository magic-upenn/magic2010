function ClearImages(handles,preview,ind,opt)

if ind>1
    if opt
        H = fspecial('motion',20,45);
        im = imfilter(handles.handles.ImageData(ind-1).ImageRGB,H,'replicate');
        dummy = im;
        dummy1 = im;
        if preview
            axes(handles.image_preview);
            image(dummy1);
            axis normal;
            axis off
        end
    else
        dummy1 = handles.ImageData(ind).ImageRGB;
        if preview
            axes(handles.image_preview);
            image(dummy1);
            axis normal;
            axis off
        end
    end
else
    dummy = ones(500,750,3);
    %     dummy = imread('axes_background.png');
    dummy1 = ones(300,450,3);
    dummy2 = ones(300,450,3);
    axes(handles.image_calib1);
    image(dummy);
    axis image;
    axis off
    if preview
        axes(handles.image_preview);
        image(dummy1);
        axis normal;
        axis off
    end
    axes(handles.trans);
%     image(dummy2);
%     axis image;
    axis off
end
drawnow