function [omni_sm, front_sm, omni_cands, front_cands, omni_stats, front_stats] = red_detect_cams()
	global times
	total = tic; 
%	omni  = get_image(0,1); 
%	front = get_image(1,3);
	tic; 
	omni  = get_test_image(0,5); 
	front = get_test_image(1,5);
	times.get = toc; 
	circle = [600,800,650];
	tic
	front = imrotate(front,180); 
	times.rotate = toc; 
	tic
	omni_flat = linear_unroll(omni,circle(2),circle(1),circle(3));
	times.unroll = toc; 
	tic
	[red,omni_stats] = find_red_candidates(omni_flat); 
	times.find_omni = toc; 
	tic
	[red,front_stats] = find_red_candidates(front);
	times.find_front = toc;
	tic 
	omni_cand1 = draw_cand_zoom(omni_stats,1,omni_flat);  
	front_cand1 = draw_cand_zoom(front_stats,1,front);  
	omni_cand2 = draw_cand_zoom(omni_stats,2,omni_flat);  
	front_cand2 = draw_cand_zoom(front_stats,2,front);  
	omni_cand3 = draw_cand_zoom(omni_stats,3,omni_flat);  
	front_cand3 = draw_cand_zoom(front_stats,3,front);  
	omni_cands = {omni_cand1,omni_cand2,omni_cand3}; 
	front_cands = {front_cand1,front_cand2,front_cand3}; 
	times.zoom = toc; 
	tic;
	front_sm = imresize(front,[240,320],'nearest');
	times.resize_front = toc; 
	tic;
	omni_sm  = imresize(omni_flat,[155,775],'nearest');
	times.resize_omni = toc; 
	omni_scale = size(omni_sm,1)/size(omni_flat,1);   
	front_scale = size(front_sm,1)/size(front,1);   
	omni_stats(:,2:end) = round(omni_stats(:,2:end) * omni_scale); 
	front_stats(:,2:end) = round(front_stats(:,2:end) * front_scale); 
	times.total = toc(total)

function [img] = get_test_image(type,num)
	usbo{1} = 'usbo-05.jpg';
	usbo{2} = 'usbo-10.jpg';
	usbo{3} = 'usbo-15.jpg';
	usbo{4} = 'usbo-20.jpg';
	usbo{5} = 'usbo-30.jpg';
	usbo{6} = 'usbo-35.jpg';
	usbo{7} = 'usbo-45.jpg';
	usbo{8} = 'usbo-50.jpg';
	usbo{9} = 'usbo-55.jpg';

	usbofront{1} = 'usbo-front-05.jpg';  
	usbofront{2} = 'usbo-front-10.jpg'; 
	usbofront{3} = 'usbo-front-15.jpg'; 
	usbofront{4} = 'usbo-front-20.jpg'; 
	usbofront{5} = 'usbo-front-30.jpg'; 
	usbofront{6} = 'usbo-front-35.jpg'; 
	usbofront{7} = 'usbo-front-45.jpg'; 
	usbofront{8} = 'usbo-front-50.jpg'; 
	usbofront{9} = 'usbo-front-55.jpg'; 
	if type == 0
		img = imread(usbo{num}); 
	else 
		img = imread(usbofront{num}); 
		img = img(1:2:end,1:2:end,:); 
	end	
