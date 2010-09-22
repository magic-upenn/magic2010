function red_detect_file(file)
global UIMG; 
global IMG;
img = imread(file); [best,best_mask,bound] = find_center(img); uimg = linear_unroll(img,best(2),best(1),best(3)); find_red_candidates(uimg);
UIMG = uimg; 
IMG = img;  
