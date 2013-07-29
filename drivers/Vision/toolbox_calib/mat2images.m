% scriupt to extract images from a .mat file to be used by the image
% processor

images = load('images.mat');
for i=1:length(images.dat);
    imwrite(images.dat{i}, ['Image_', num2str(i), '.tif'], 'tif');
end