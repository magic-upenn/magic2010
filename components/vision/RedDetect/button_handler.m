function button_handler(chr,gui)
	global GLOBALS IMAGES	
	num = str2num(chr);
%	if strcmp(gui,'track')
%		if ~isempty(num)
%			num
%			if num == 0
%				GLOBALS.track_fns.toggle_control(); 	
%			else
%				GLOBALS.track_fns.set_robot(num); 	
%			end
%		elseif strcmp(chr, '.')
%		elseif strcmp(chr, '+')
%		elseif strcmp(chr, '-')
%		elseif strcmp(chr, '*')
%		elseif strcmp(chr, '|')
%		elseif strcmp(chr, '\')
%		elseif strcmp(chr, '/')
%		elseif strcmp(chr, 'enter')
%		elseif strcmp(chr, 'del')
%		elseif strcmp(chr, 'left')
%			GLOBALS.track_fns.set_cand([],[],[],[GLOBALS.track_toggle,1]); 
%		elseif strcmp(chr, 'down')
%			GLOBALS.track_fns.set_cand([],[],[],[GLOBALS.track_toggle,2]); 
%		elseif strcmp(chr, 'up')
%			focus = GLOBALS.track_toggle; 
%			id = GLOBALS.track_focus(focus).id;
%			cand = GLOBALS.track_focus(focus).cand;
%			x = mean(IMAGES(id).front_stats(cand,4:5));
%			po = front_pixel_to_omni(IMAGES(id).omni,IMAGES(id).front,x); 
%			angle = pixel_to_angle(IMAGES(id).omni,po);
%			GLOBALS.front_fns.lookat(GLOBALS.focus, angle,'track');  
%		elseif strcmp(chr, 'right')
%			GLOBALS.track_fns.set_cand([],[],[],[GLOBALS.track_toggle,3]); 
%		elseif strcmp(chr, 'w') | strcmp(chr,'['); 
%		elseif strcmp(chr, 'v') | strcmp(chr,']'); 
%		else 
%		end
%	else 
	GLOBALS.vision_fns.set_status(strcat('Got key: ',chr)); 
	if ~isempty(num) & ~strcmp(chr,'i') & ~strcmp(chr,'j') 
		if num == 0
			GLOBALS.focus = mod(GLOBALS.focus,2) + 1;
			GLOBALS.vision_fns.set_status(sprintf('Toggled focus to: %d',GLOBALS.focus)); 
		else 
			GLOBALS.vision_fns.set_focus(num); 
		end
		GLOBALS.vision_fns.updateGui();
	elseif strcmp(chr, '.')
		swap_out = GLOBALS.bids(GLOBALS.focus);  
		GLOBALS.bids(GLOBALS.focus) = GLOBALS.bids(9); 
		GLOBALS.bids(9) = swap_out;  
		GLOBALS.vision_fns.set_status(sprintf('Gave focus to: %d',GLOBALS.bids(GLOBALS.focus))); 
		GLOBALS.vision_fns.updateGui();
	elseif strcmp(chr, '*')
		GLOBALS.vision_fns.explore_Callback();    
	elseif strcmp(chr, '/')
		GLOBALS.vision_fns.neutralized_Callback();    
	elseif strcmp(chr, '+')
		GLOBALS.vision_fns.lazer_on_Callback();    
	elseif strcmp(chr, '-')
		GLOBALS.vision_fns.lazer_off_Callback();     
	elseif strcmp(chr, 'enter')
		GLOBALS.vision_fns.announce_ooi_Callback();    
	elseif strcmp(chr, 'del')
		GLOBALS.vision_fns.renounce_ooi_Callback();    

	elseif strcmp(chr, 'a') 
		GLOBALS.vision_fns.car_Callback();            
	elseif strcmp(chr, 'o') | strcmp(chr, 's')
		GLOBALS.vision_fns.red_ooi_Callback();     
	elseif strcmp(chr, 'e') | strcmp(chr, 'd')
		GLOBALS.vision_fns.door_Callback();          
	elseif strcmp(chr, ';') | strcmp(chr, 'z')
		GLOBALS.vision_fns.still_mobile_Callback();     
	elseif strcmp(chr, 'q') | strcmp(chr, 'x')
		GLOBALS.vision_fns.yellow_ooi_Callback(); 
	elseif strcmp(chr, 'j') | strcmp(chr, 'c')
		GLOBALS.vision_fns.mobile_ooi_Callback();     

	elseif strcmp(chr, 'left') 
		GLOBALS.vision_fns.nudge_left_Callback();          
	elseif strcmp(chr, 'right'); 
		GLOBALS.vision_fns.nudge_right_Callback();          
	elseif strcmp(chr, 'up')
		GLOBALS.vision_fns.lazer_up_Callback();       
	elseif strcmp(chr, 'down')
		GLOBALS.vision_fns.lazer_down_Callback();     
	else 
		GLOBALS.vision_fns.set_status(strcat('Invalid hotkey',chr)); 
	end

