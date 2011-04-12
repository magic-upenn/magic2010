function ModOutputMap(phase)
% fxn outputs a series of tif files and one text file with data from the
% current phase

global GMAP OOI ROBOT_PATH OOI_PATH NC_PATH MAGIC_CONSTANTS;
%load geotiff_option;
%color definitions:
CFILE = [0 44 207]/255;
CSCALE = [0 50 140]/255;
CDUNK = [226 226 227]/255;
CLUNK = [237 237 238]/255;
CSTART = [255 200 0]/255;
CWALL = [0 40 120]/255;
CFREEMIN = [128 128 128]/255;
CFREEMAX = [255 255 255]/255;
CFREEDEL = CFREEMAX - CFREEMIN;
COOI = [240 10 10]/255;
COOITEXT = [25 250 25]/255; % should be 255 255 255
CRPATH = [120 0 140]/255;
COOIPATH = [240 10 10]/255;
CNCPATH = [0 255 0]/255;

circ_x = 1.5*cos([0:.1:2*pi]);
circ_y = 1.5*sin([0:.1:2*pi]);

% add text for filename and scale marks
printname = ['MAGIC2010\_UPENN\_Mission' num2str(phase)];
filename = ['MAGIC2010_UPENN_Mission' num2str(phase)];
h=figure(99);

%load map and clip values
map = rot90(GMAP.data.cost);
map(map>100) = 100;
map(map < -100) = -100;
res = GMAP.resolution;
%map = imcrop(map);
[xdim ydim] = size(map); % in cells

HEADERSPACE = 1; % number of meters of space at the top of the map
MAPSIZE = 20; % size in meters of each small map
DPI = 200;  % DPI for full map
DPIs = 200;  % DPI for small maps

fid = fopen([filename '_OOI_data'], 'w');
fprintf(fid, 'Serial\tType\t\tUTM N\t\tUTM E\t\tShirt #\n');
% serialize all OOI's
% 1 = red barrel
% 2 = red barrel neutralized
% 3 = moving POI
% 4 = neutralized moving POI
% 5 = stationary POI
% 6 = yellow barrel
% 7 = doorway
% 8 = car
mOOI = 1;
sOOI = 1;
for idx = 1:size(OOI,2)
    if ((OOI(idx).type == 1) || (OOI(idx).type == 2))
        OOI(idx).serial = ['S' num2str(sOOI)];
        sOOI = sOOI + 1;
        fprintf(fid, '%s \tStatic OOI \t% 7.1f \t% 6.1f\n', OOI(idx).serial, OOI(idx).x, OOI(idx).y);
    elseif ((OOI(idx).type == 3) || (OOI(idx).type == 4)||(OOI(idx).type == 5))
        OOI(idx).serial = ['M' num2str(mOOI)];
        mOOI = mOOI + 1;
        fprintf(fid, '%s \tMobile OOI \t% 7.1f \t% 6.1f \t%i\n', OOI(idx).serial, OOI(idx).x, OOI(idx).y, OOI(idx).shirtNumber);
    elseif (OOI(idx).type == 6)
        OOI(idx).serial = ['TW'];
        fprintf(fid, '%s \t\t\t% 7.1f \t% 6.1f\n', OOI(idx).serial, OOI(idx).x, OOI(idx).y);
    elseif (OOI(idx).type == 7)
        OOI(idx).serial = ['AX'];
        fprintf(fid, '%s \t\t\t% 7.1f \t% 6.1f\n', OOI(idx).serial, OOI(idx).x, OOI(idx).y);
    elseif (OOI(idx).type == 8)
        OOI(idx).serial = ['PV'];
        fprintf(fid, '%s \t\t\t% 7.1f \t% 6.1f\n', OOI(idx).serial, OOI(idx).x, OOI(idx).y);
    end
end

fclose(fid);
% number of 20m sections in each direction
num_x = floor(xdim*res/MAPSIZE) + 1;
num_y = floor(ydim*res/MAPSIZE) + 1;

%adjust map to be whole multiple of squares
map(num_x*MAPSIZE/res, num_y*MAPSIZE/res) =0;

mapEoffset = MAGIC_CONSTANTS.mapEastOffset - MAGIC_CONSTANTS.mapEastMin;
mapNoffset = MAGIC_CONSTANTS.mapNorthOffset - MAGIC_CONSTANTS.mapNorthMin;

% pre screen paths
RPATH(1).x=[];
RPATH(1).y=[];
NPATH=[];
OPATH=[];

%convert paths to cell indices
for ID = 1:size(ROBOT_PATH,2)
    if ~isempty(ROBOT_PATH(ID).x)
        RPATH(ID).x = floor((ROBOT_PATH(ID).x + mapEoffset));
        RPATH(ID).y = floor((ROBOT_PATH(ID).y + mapNoffset));
    else
        RPATH(ID).x = [];
        RPATH(ID).y = [];
    end
end

for ID = 1:size(OOI_PATH,2)
    if ~isempty(OOI_PATH(ID))
        OPATH(ID).x = floor((OOI_PATH(ID).x -MAGIC_CONSTANTS.mapEastMin));
        OPATH(ID).y = floor((OOI_PATH(ID).y -MAGIC_CONSTANTS.mapNorthMin));
    else
        OPATH(ID) = [];
    end
end

for ID =1:size(NC_PATH, 2)
    if ~isempty(NC_PATH(ID))
        NPATH(ID).x = floor((NC_PATH(ID).x -MAGIC_CONSTANTS.mapEastMin));
        NPATH(ID).y = floor((NC_PATH(ID).y -MAGIC_CONSTANTS.mapNorthMin));
    else
        NPATH(ID) = [];
    end
end

%{
% print a full map
minx = 1; miny =1;
maxx = xdim; maxy = ydim;

% setup the plot map
plot_map = map(minx:maxx, miny:maxy);
plot_map = vertcat(zeros(HEADERSPACE,ydim), plot_map);

%setup the output map
out_map1(:,:) = repmat(CDUNK(1), xdim+HEADERSPACE, ydim);
out_map2(:,:) = repmat(CDUNK(2), xdim+HEADERSPACE, ydim);
out_map3(:,:) = repmat(CDUNK(3), xdim+HEADERSPACE, ydim);

%make grid background
for gx= 0:(xdim*res -1)
	for gy=0:(ydim*res -1)
		if (mod(gx+gy, 2))
			out_map1((gx/res)+1+HEADERSPACE:((gx+1)/res)+HEADERSPACE, (gy/res)+1:((gy+1)/res)) = CLUNK(1);
			out_map2((gx/res)+1+HEADERSPACE:((gx+1)/res)+HEADERSPACE, (gy/res)+1:((gy+1)/res)) = CLUNK(2);
			out_map3((gx/res)+1+HEADERSPACE:((gx+1)/res)+HEADERSPACE, (gy/res)+1:((gy+1)/res)) = CLUNK(3);
		end
	end
end

% plot the known
pmidx = plot_map < 0;
out_map1(pmidx) = CFREEMAX(1) - (CFREEDEL(1).*(plot_map(pmidx)+100)/200);
out_map2(pmidx) = CFREEMAX(2) - (CFREEDEL(2).*(plot_map(pmidx)+100)/200);
out_map3(pmidx) = CFREEMAX(3) - (CFREEDEL(3).*(plot_map(pmidx)+100)/200);

%plot the presumed free by movement
pmidx = plot_map > 2;
out_map1(pmidx) = CFREEMAX(1) - (CFREEDEL(1).*(plot_map(pmidx)+100)/200);
out_map2(pmidx) = CFREEMAX(2) - (CFREEDEL(2).*(plot_map(pmidx)+100)/200);
out_map3(pmidx) = CFREEMAX(3) - (CFREEDEL(3).*(plot_map(pmidx)+100)/200);

%plot the walls
pmidx = plot_map >=75;
out_map1(pmidx) = CWALL(1);
out_map2(pmidx) = CWALL(2);
out_map3(pmidx) = CWALL(3);

out_map = cat(3, out_map1, out_map2, out_map3);

clf(h); hold off; image(out_map); hold on; axis equal; axis tight;
set(gca,'Units','Normalized','Position',[0 0 1 1]);

%add the filename
text(10, 10, [printname '\_full'], 'Color', CFILE, 'FontSize', 8);

% scale
plot([10 10], [25.5 35.5], 'Color', CSCALE, 'LineWidth', .2);
plot([9 11], [25.5 25.5], 'Color', CSCALE, 'LineWidth', .2);
plot([9 11], [35.5 35.5], 'Color', CSCALE, 'LineWidth', .2);
text(12, 40, '1m', 'Color', CSCALE, 'FontSize', 6);

% orientation
plot([55 55 50], [33 38 38], 'Color', CSCALE, 'LineWidth', .2);
text(61, 31, 'x', 'Color', CSCALE, 'FontSize', 4);
text(47, 41, 'y', 'Color', CSCALE, 'FontSize', 4);

% robot start
for ID = 1:size(RPATH,2)
	if ~isempty(RPATH(ID).x)
		patch(RPATH(ID).y(1)+[-1 0 1]-miny, RPATH(ID).x(1)+[1 -2 1]-minx+HEADERSPACE, CSTART);
	end
end

% plot the robot, OOI and NC paths
for ID =1:size(RPATH,2)
	if ~isempty(RPATH(ID).x)
		plot(RPATH(ID).y-miny, RPATH(ID).x- minx+HEADERSPACE, 'Color', CRPATH, 'LineWidth', .02);
	end
end

for ID = 1:size(OPATH,2)
	if ~isempty(OPATH(ID))
		plot(OPATH(ID).y-miny, OPATH(ID).x- minx +HEADERSPACE, 'Color', COOIPATH, 'LineWidth', .02);
	end
end

for ID =1:size(NPATH,2)
	if ~isempty(NPATH(ID))
		plot(NPATH(ID).y-miny, NPATH(ID).x - minx +HEADERSPACE, 'Color', CNCPATH, 'LineWidth', .02);
	end
end

% OOI info
for oidx=1: size(OOI,2)
	xx = (OOI(oidx).x + mapEoffset)/res;
	yy = (OOI(oidx).y + mapNoffset)/res;
	if ((xx>=minx) && (xx <=maxx) && (yy>=miny) && (yy<=maxy))
		patch(circ_y+yy-miny, circ_x+xx-minx, COOI, 'EdgeColor', 'none');
		text(yy-miny+.4, xx-minx, OOI(oidx).serial, 'Color', COOITEXT, 'FontSize', 4);
	end
end

set(gca, 'Position', [0 0 1 1], 'Visible', 'off', 'ActivePositionProperty', 'Position');
orient tall
drawnow;
%output the file
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperPosition', [0 0 size(map,2)/100 (size(map,1)+ HEADERSPACE)/100]);

set(gca,'Units','Normalized','Position',[0 0 1 1])
%tightmap;
%saveas(gcf, [filename '_full.tif'], 'tiff');
print(h, '-dtiff',['-r0'],  [filename '_full.tif']);
 [img] = imread([filename '_full.tif']);

 %remove borders
idx = sum(img,1)/255;
idx = idx(:,:,1);
idx = find(idx==size(img, 1));
img(:,idx,:) = [];
idx = sum(img,2)/255;
idx = idx(:,:,1);
idx = find(idx==size(img,2));
img(idx,:,:) = [];



imwrite(img, [filename '_full.tif'], 'tif');
%[img cmp] = imread([filename '_full.tif']);
% option.Colormap = cmp*65535;
% option.ModelTiepointTag(4) = MAGIC_CONSTANTS.mapEastMin;
% option.ModelTiepointTag(5) = MAGIC_CONSTANTS.mapNorthMax + HEADERSPACE;

% geotiffwrite([filename '_full.tif'],[],img,8,option);
%}

% make small maps
F=[];
for x=1:num_x
    Fx = [];
    for y=1:num_y
        figure(99);
        %         x =3; y=8;
        % calc endpoints of map in meters
        minx = (x-1)*MAPSIZE/res +1;
        maxx = (x*MAPSIZE)/res;
        miny = (y-1)*MAPSIZE/res +1;
        maxy = (y*MAPSIZE)/res;

        % setup the plot map
        plot_map = map(minx:maxx, miny:maxy);
        plot_map = vertcat(zeros(HEADERSPACE/res,200), plot_map);

        %setup the output map
        out_map1 = repmat(CDUNK(1), (MAPSIZE+HEADERSPACE)/res, MAPSIZE/res);
        out_map2 = repmat(CDUNK(2), (MAPSIZE+HEADERSPACE)/res, MAPSIZE/res);
        out_map3 = repmat(CDUNK(3), (MAPSIZE+HEADERSPACE)/res, MAPSIZE/res);

        %make grid background
        for gx= 0:(MAPSIZE+HEADERSPACE -1)
            for gy=0:(MAPSIZE -1)
                if (mod(gx+gy, 2))
                    out_map1((gx/res)+1:((gx+1)/res), (gy/res)+1:((gy+1)/res)) = CLUNK(1);
                    out_map2((gx/res)+1:((gx+1)/res), (gy/res)+1:((gy+1)/res)) = CLUNK(2);
                    out_map3((gx/res)+1:((gx+1)/res), (gy/res)+1:((gy+1)/res)) = CLUNK(3);
                end
            end
        end

        % plot the known
        pmidx = plot_map < 0;
        out_map1(pmidx) = CFREEMAX(1) - (CFREEDEL(1).*(plot_map(pmidx)+100)/200);
        out_map2(pmidx) = CFREEMAX(2) - (CFREEDEL(2).*(plot_map(pmidx)+100)/200);
        out_map3(pmidx) = CFREEMAX(3) - (CFREEDEL(3).*(plot_map(pmidx)+100)/200);

        %plot the presumed free by movement
        pmidx = plot_map > 2;
        out_map1(pmidx) = CFREEMAX(1) - (CFREEDEL(1).*(plot_map(pmidx)+100)/200);
        out_map2(pmidx) = CFREEMAX(2) - (CFREEDEL(2).*(plot_map(pmidx)+100)/200);
        out_map3(pmidx) = CFREEMAX(3) - (CFREEDEL(3).*(plot_map(pmidx)+100)/200);

        %plot the walls
        pmidx = plot_map >=75;
        out_map1(pmidx) = CWALL(1);
        out_map2(pmidx) = CWALL(2);
        out_map3(pmidx) = CWALL(3);

        out_map = cat(3, out_map1, out_map2, out_map3);

        clf(h);
        set(gcf, 'Units', 'pixels', 'Position', [0 0 MAPSIZE*50 (MAPSIZE+HEADERSPACE)*50]);%,'OuterPosition', [0 0 1000 1100]);
        set(gca, 'Position', [0 0 1 1], 'Visible', 'off', 'ActivePositionProperty', 'Position', 'Xlim', [0 MAPSIZE], 'Ylim', [0 MAPSIZE+HEADERSPACE]);
        %orient tall;
        hold on;
        image([0 20], [0 22], out_map);

        %add the filename
        text(.5, 20.5, [printname '\_' num2str(x) '\_' num2str(y)], 'Color', CFILE, 'FontSize', 10);

        % scale
        plot([11 11], [20 21], 'Color', CSCALE);
        plot([10.9 11.1], [20 20], 'Color', CSCALE);
        plot([10.9 11.1], [21 21], 'Color', CSCALE);
        text(11.2, 20.5, '1m', 'Color', CSCALE, 'FontSize', 8);

        % orientation
        plot([13.5 13.5 13.0], [20.8 20.3 20.3], 'Color', CSCALE);
        text(13.6, 20.6, 'x', 'Color', CSCALE, 'FontSize', 6);
        text(13.0, 20.3, 'y', 'Color', CSCALE, 'FontSize', 6);

        % robot start
        for ID = 1:size(RPATH,2)
            if ~isempty(RPATH(ID).x)
                if((RPATH(ID).x(1)>=minx) && (RPATH(ID).x(1) <= maxx) && (RPATH(ID).y(1) >=miny) && (RPATH(ID).y(1) <= maxy))
                    patch(RPATH(ID).y(1)+[-.2 0 .2]-miny, RPATH(ID).x(1)+[.2 -.4 .2]-minx+HEADERSPACE, CSTART);
                end
            end
        end

        % plot the robot, OOI and NC paths
        for ID =1:size(RPATH,2)
            if ~isempty(RPATH(ID).x)
                robot_temp = ((RPATH(ID).x>=minx) & (RPATH(ID).x <= maxx) & (RPATH(ID).y >=miny) & (RPATH(ID).y <= maxy));
                if ~isempty(robot_temp)
                    plot(RPATH(ID).y(robot_temp)-miny, RPATH(ID).x(robot_temp)- minx+HEADERSPACE, 'Color', CRPATH, 'LineWidth', .02);
                end
            end
        end

        for ID = 1:size(OPATH,2)
            if ~isempty(OPATH(ID))
                ooi_temp = ((OPATH(ID).x>=minx) & (OPATH(ID).x <= maxx) & (OPATH(ID).y >=miny) & (OPATH(ID).y <= maxy));
                if ~isempty(ooi_temp)
                    plot(OPATH(ID).y(ooi_temp)-miny, OPATH(ID).x(ooi_temp)- minx +HEADERSPACE, 'Color', COOIPATH, 'LineWidth', .02);
                end
            end
        end

        for ID =1:size(NPATH,2)
            if ~isempty(NPATH(ID))
                nc_temp = ((NPATH(ID).x>=minx) & (NPATH(ID).x <= maxx) & (NPATH(ID).y >=miny) & (NPATH(ID).y <= maxy));
                if ~isempty(nc_temp)
                    plot(NPATH(ID).y(nc_temp)-miny, NPATH(ID).x(nc_temp) - minx +HEADERSPACE, 'Color', CNCPATH, 'LineWidth', .02);
                end
            end
        end

        % OOI info
        for oidx=1: size(OOI,2)
            xx = (OOI(oidx).x + mapEoffset)/res;
            yy = (OOI(oidx).y + mapNoffset)/res;
            if ((xx>=minx) && (xx <=maxx) && (yy>=miny) && (yy<=maxy))
                patch(circ_y+yy-miny, circ_x+xx-minx, COOI, 'EdgeColor', 'none');
                text(yy-miny, xx-minx, OOI(oidx).serial, 'Color', COOITEXT, 'FontSize', 12);
            end
        end


        drawnow;
        %output the file
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        set(gcf, 'PaperPosition', [0 0 size(out_map,2)*5 (size(out_map,1)*5+ HEADERSPACE*50)]);

        print(h, '-dtiff', ['-r1' ], [filename '_' num2str(x) '_' num2str(y) '.tif']);
        set(gcf, 'Position', [0 0 1000 1100], 'MenuBar', 'None', 'DockControls', 'Off');
        %     f = getframe(99, [0 0 1000 1100]);
        % imwrite(f.cdata, [filename '_' num2str(x) '_' num2str(y) '.tif']);
        %    F{x,y} = f.cdata(2:end, :, :);

        [img] = imread([filename '_' num2str(x) '_' num2str(y) '.tif']);
        img(:,:,1) = flipud(img(:,:,1));
        img(:,:,2) = flipud(img(:,:,2));
        img(:,:,3) = flipud(img(:,:,3));
        imwrite(img,[filename '_' num2str(x) '_' num2str(y) '.tif']);
        UTMn = MAGIC_CONSTANTS.mapNorthMax - (x-1)*MAPSIZE + HEADERSPACE; % extra one to accont for headerspace
        UTMe = MAGIC_CONSTANTS.mapEastMin + (y-1)*MAPSIZE;
        scale = .02;
                
        writegeofile([filename '_' num2str(x) '_' num2str(y) '.txt'], UTMn, UTMe, scale);
        
        

        %         print(h, '-dtiff','-r600',  [filename '_full.tif']);
        %[img] = imread([filename '_' num2str(x) '_' num2str(y) '.tif']);
        img(:,:,1) = flipud(img(:,:,1));
        img(:,:,2) = flipud(img(:,:,2));
        img(:,:,3) = flipud(img(:,:,3));
        %img = img((size(img,1) - size(img,2)+1):end, :,:);
        img = img(1:1000, :,:);
        Fx = horzcat(Fx, imresize(img, [400 400]));



    end
    F = vertcat(Fx, F);
end
%imwrite(F, [filename  '_full.tif'], 'tiff'); 

clf(h);
set(gcf, 'Units', 'pixels', 'Position', [0 0 size(F,2)*20 size(F,1)*20]);%,'OuterPosition', [0 0 1000 1100]);
set(gca, 'Position', [0 0 1 1], 'Visible', 'off', 'ActivePositionProperty', 'Position', 'Xlim', [0 size(F,1)/20], 'Ylim', [0 size(F,2)/20]);

hold on;
image([0 size(F,1)/20], [0 size(F,2)/20], F);

%add the filename
topb = size(F, 2)/20;


text(.5, topb - 3, [printname '\_full'], 'Color', CFILE, 'FontSize', 8);

% scale
plot([31 31], [topb-2 topb-3], 'Color', CSCALE);
plot([30.9 31.1], [topb-2 topb-2], 'Color', CSCALE);
plot([30.9 31.1], [topb-3 topb-3], 'Color', CSCALE);
text(31.2, topb-2, '1m', 'Color', CSCALE, 'FontSize', 8);

% orientation
plot([43.5 43.5 43.0], [topb-1.2 topb-1.7 topb-1.7], 'Color', CSCALE);
text(43.6, topb-1.6, 'x', 'Color', CSCALE, 'FontSize', 6);
text(43.0, topb-1.7, 'y', 'Color', CSCALE, 'FontSize', 6);

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperPosition', [0 0 size(F,2) size(F,1) ]);

print(h, '-dtiff', ['-r1' ], [filename  '_full.tif']);

UTMn = MAGIC_CONSTANTS.mapNorthMax;
UTMe = MAGIC_CONSTANTS.mapEastMin;
scale = .02;

writegeofile([filename  '_full.txt'], UTMn, UTMe, scale);



end



function writegeofile(filename, utmn, utme, scl)
% fxn takes the filename, utm coordinates of a corner and the resolution
% and outputs geotiff data file

fid = fopen(filename, 'w');
fprintf(fid, 'Geotiff_Information:\n Version: 1\n Key_Revision: 1.0\n Tagged_Information:\n  ModelTiepointTag (2,3):\n 0 0 0 \n');
fprintf(fid, '%f   %f   0\n', utme, utmn);
fprintf(fid, ' ModelPixelScaleTag (1,3):\n');
fprintf(fid, ' %f %f 0\n', scl, scl);
fprintf(fid, ' End_Of_Tags. \n Keyed_Information:\n GTModelTypeGeoKey (Short,1): ModelTypeProjected\n GTRasterTypeGeoKey (Short,1): RasterPixelIsArea\n ');
fprintf(fid, ' ProjectedCSTypeGeoKey (Short,1): PCS_WGS84_UTM_zone_54S\n ');
fprintf(fid, ' ProjLinearUnitsGeoKey (Short,1): Linear_Meter\n  End_Of_Keys.\n   End_Of_Geotiff.\n');
fprintf(fid, ' PCS = 32754 (name unknown)\n  Projection = 16154 ()\n Projection Method: CT_TransverseMercator\n');
fprintf(fid, ' ProjNatOriginLatGeoKey: 0.000000 (  0d 0'' 0.00"N)\n ProjNatOriginLongGeoKey: 141.000000 (141d 0'' 0.00"E)\n');
fprintf(fid, ' ProjScaleAtNatOriginGeoKey: 0.999600\n ProjFalseEastingGeoKey: 500000.000000 m\n ProjFalseNorthingGeoKey: 10000000.000000 m\n GCS: 4326/WGS 84\n');
fprintf(fid, ' Datum: 6326/World Geodetic System 1984\n Ellipsoid: 7030/WGS 84 (6378137.00,6356752.31)\n Prime Meridian: 8901/Greenwich (0.000000/  0d 0'' 0.00"E)\n Projection Linear Units: 9001/metre (1.000000m)\n');
fclose(fid);
end
