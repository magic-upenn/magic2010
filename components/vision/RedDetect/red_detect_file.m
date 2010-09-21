function red_detect_file(file)
img = imread(file); [best,best_mask,bound] = find_center(img); uimg = linear_unroll(img,best(2),best(1),best(3)); find_red_candidates(uimg); 
