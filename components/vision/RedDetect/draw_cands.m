function draw_cands(stats,img)
	imagesc(img); 
	if isempty(stats)
		return
	end
	for i = 1:min(size(stats,1),25)
		linecolor = 'blue';
		if i == 3
			linecolor = 'red';
		end
		if i == 2
			linecolor = 'yellow';
		end
		if i == 1
			linecolor = 'green';
		end
		bb = stats(i,2:end);
		bb = max(bb,1);  
		line([bb(3),bb(4)],[bb(1),bb(1)],'Color',linecolor,'LineWidth',2);
		line([bb(3),bb(4)],[bb(2),bb(2)],'Color',linecolor,'LineWidth',2);
		line([bb(3),bb(3)],[bb(1),bb(2)],'Color',linecolor,'LineWidth',2);
		line([bb(4),bb(4)],[bb(1),bb(2)],'Color',linecolor,'LineWidth',2);
	end
