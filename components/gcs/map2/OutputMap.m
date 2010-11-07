function OutputMap(phase)
% fxn outputs a series of tif files and one text file with data from the
% current phase

global GMAP OOI ROBOT_PATH OOI_PATH NC_PATH MAGIC_CONSTANTS;
load geotiff_option;
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
map = GMAP.data.cost;
map(map>100) = 100;
map(map < -100) = -100;
res = GMAP.resolution;
%map = imcrop(map);
[xdim ydim] = size(map); % in cells

HEADERSPACE = 20; % number of pixels of space at the top of the map
MAPSIZE = 20; % size in meters of each small map
DPI = 200;  % DPI for full map
DPIs = 200;  % DPI for small maps


fid = fopen([filename '.txt'], 'w');
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
        RPATH(ID).x = floor((ROBOT_PATH(ID).x + mapEoffset)/res);
        RPATH(ID).y = floor((ROBOT_PATH(ID).y + mapNoffset)/res);
    else
        RPATH(ID).x = [];
        RPATH(ID).y = [];
    end
end

for ID = 1:size(OOI_PATH,2)
    if ~isempty(OOI_PATH(ID))
        OPATH(ID).x = floor((OOI_PATH(ID).x -MAGIC_CONSTANTS.mapEastMin)/res);
        OPATH(ID).y = floor((OOI_PATH(ID).y -MAGIC_CONSTANTS.mapNorthMin)/res);
    else
        OPATH(ID) = [];
    end
end

for ID =1:size(NC_PATH, 2)
    if ~isempty(NC_PATH(ID))
        NPATH(ID).x = floor((NC_PATH(ID).x -MAGIC_CONSTANTS.mapEastMin)/res);
        NPATH(ID).y = floor((NC_PATH(ID).y -MAGIC_CONSTANTS.mapNorthMin)/res);
    else
        NPATH(ID) = [];
    end
end


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

%add the filename
text(10, 5, [printname '\_full'], 'Color', CFILE, 'FontSize', 8);

% scale
plot([10 10], [20.5 30.5], 'Color', CSCALE, 'LineWidth', .2);
plot([9 11], [20.5 20.5], 'Color', CSCALE, 'LineWidth', .2);
plot([9 11], [30.5 30.5], 'Color', CSCALE, 'LineWidth', .2);
text(12, 30, '1m', 'Color', CSCALE, 'FontSize', 6);

% orientation
plot([55 55 50], [23 28 28], 'Color', CSCALE, 'LineWidth', .2);
text(61, 21, 'x', 'Color', CSCALE, 'FontSize', 4);
text(47, 31, 'y', 'Color', CSCALE, 'FontSize', 4);

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




set(gca, 'Position', [.0 .0 1 1], 'Visible', 'off', 'ActivePositionProperty', 'Position');
orient tall
drawnow;
%output the file
% print(h, '-dtiff','-r300',  [filename '_full.tif']);
%img = get( 99,'Cdata');
print(h, '-dtiff',['-r' num2str(DPI)],  [filename '_full.tif']);
[img] = imread([filename '_full.tif']);
option.ModelTiepointTag(4) = MAGIC_CONSTANTS.mapEastMin;
option.ModelTiepointTag(5) = MAGIC_CONSTANTS.mapNorthMax + HEADERSPACE;

geotiffwrite([filename '_full.tif'],[],img,8,option);


% make small maps
%
for x=1:num_x
    for y=1:num_y
        %         x =3; y=8;
        % calc endpoints of map
        minx = (x-1)*MAPSIZE/res +1;
        maxx = (x*MAPSIZE)/res;
        miny = (y-1)*MAPSIZE/res +1;
        maxy = (y*MAPSIZE)/res;
        
        % setup the plot map
        plot_map = map(minx:maxx, miny:maxy);
        plot_map = vertcat(zeros(HEADERSPACE,200), plot_map);
        
        %setup the output map
        out_map1 = repmat(CDUNK(1), MAPSIZE/res+HEADERSPACE, MAPSIZE/res);
        out_map2 = repmat(CDUNK(2), MAPSIZE/res+HEADERSPACE, MAPSIZE/res);
        out_map3 = repmat(CDUNK(3), MAPSIZE/res+HEADERSPACE, MAPSIZE/res);
        
        %make grid background
        for gx= 0:(MAPSIZE+HEADERSPACE*res -1)
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
        
        clf(h); hold off; image(out_map); hold on; axis equal; axis tight;
        
        %add the filename
        text(10, 5, [printname '\_' num2str(x) '\_' num2str(y)], 'Color', CFILE, 'FontSize', 10);
        
        % scale
        plot([10 10], [10.5 20.5], 'Color', CSCALE);
        plot([9 11], [10.5 10.5], 'Color', CSCALE);
        plot([9 11], [20.5 20.5], 'Color', CSCALE);
        text(12, 15, '1m', 'Color', CSCALE, 'FontSize', 8);
        
        % orientation
        plot([35 35 30], [13 18 18], 'Color', CSCALE);
        text(36, 13, 'x', 'Color', CSCALE, 'FontSize', 6);
        text(30, 16, 'y', 'Color', CSCALE, 'FontSize', 6);
        
        % robot start
        for ID = 1:size(RPATH,2)
            if ~isempty(RPATH(ID).x)
                if((RPATH(ID).x(1)>=minx) && (RPATH(ID).x(1) <= maxx) && (RPATH(ID).y(1) >=miny) && (RPATH(ID).y(1) <= maxy))
                    patch(RPATH(ID).y(1)+[-1 0 1]-miny, RPATH(ID).x(1)+[1 -2 1]-minx+HEADERSPACE, CSTART);
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
                text(yy-miny+3, xx-minx, OOI(oidx).serial, 'Color', COOITEXT, 'FontSize', 12);
            end
        end
        
        
        
        
        set(gca, 'Position', [.01 .01 .98 .98], 'Visible', 'off', 'ActivePositionProperty', 'Position');
        orient tall
        drawnow;
        %output the file
        print(h, '-dtiff', ['-r' num2str(DPIs)], [filename '_' num2str(x) '_' num2str(y) '.tif']);
%         print(h, '-dtiff','-r600',  [filename '_full.tif']);
[img] = imread([filename '_' num2str(x) '_' num2str(y) '.tif']);
option.ModelTiepointTag(4) = MAGIC_CONSTANTS.mapEastMin + 20*y;
option.ModelTiepointTag(5) = MAGIC_CONSTANTS.mapNorthMax - 20*x + HEADERSPACE;

geotiffwrite([filename '_' num2str(x) '_' num2str(y) '.tif'],[],img,8,option);
        
    end
end
end

