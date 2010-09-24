function draw_cands_on_image(axeh,stats,img)
	axes(axeh);
	imagesc(img); daspect([1 1 1])
	stats = flipud(sortrows(stats,2));  
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
		bb = stats(i,3:end);
		bb = max(bb,1);  
		line([bb(3),bb(4)],[bb(1),bb(1)],'Color',linecolor,'LineWidth',2);
		line([bb(3),bb(4)],[bb(2),bb(2)],'Color',linecolor,'LineWidth',2);
		line([bb(3),bb(3)],[bb(1),bb(2)],'Color',linecolor,'LineWidth',2);
		line([bb(4),bb(4)],[bb(1),bb(2)],'Color',linecolor,'LineWidth',2);
	end
