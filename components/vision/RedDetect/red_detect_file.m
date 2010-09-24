function [uimg,stats,circle] = red_detect_file(file)
img = imread(file);
%[circle,best_mask,bound] = find_center(img); 
circle = [500,850,601]; 
uimg = linear_unroll(img,circle(2),circle(1),circle(3));
[red,stats] = find_red_candidates(uimg);
