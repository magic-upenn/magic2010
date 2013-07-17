function [arthroscope_R,arthroscope_T] = LoadOptoTrackMotion( OptoTrackerFile, NumberConnected, ObjectChooser, imagename)
% Function to load the rigid motion information produced by the
% optotracker. It looks in the OptoFile for a frame name matching the
% template passed in imagename and check if the optoinformation is valid.
% This routine already convert quaternion into rotation matix so you can
% feed any optotrackerfile
%
%    - OptoTrackerFile: location of the opto tracker file to load
%    - NumberConnected: number of connected systems (arthroscope, box, etc...)
%    - ObjectChoose: wich object we consider the arthroscope (1 or 2)
%    - iamgename: an image name of the format xxx.ext where xxx=002 and ext=tiff by example
%
% Out:

arthroscope_R = [];
arthroscope_T = [];
QUAT = 0;
TRANS  =0;

[a d f] = fileparts(imagename);
full = textread(OptoTrackerFile, '%s');

if isempty(full)
   arthroscope_R = [];
   arthroscope_T = [];
   return 
end

elements=[];
for i=1:length(full)
    if (length(imagename)+1<length(full{i}))
        if strcmp(sprintf('000%s',f),full{i}(end-length(imagename)+1:end))
            elements = i-1;
            break;
        end
    end
end

if isempty(elements)
   disp('WARNING: The OptoTracker info loader expects to have information about frame number 000. No opto information loaded... ') 
   return
end

if ~rem(elements,7) %Quaternion file
    QUAT = 1;
elseif ~rem(elements,12) %Matrix file
    TRANS = 1;
else
    disp('Error!!! Could not determine if the file is Quaternion or Transformation matrix from the first row of the OptoTracker file...');
    return
end


if TRANS
    switch NumberConnected
        case 1
            [obj1(:,1),obj1(:,2),obj1(:,3),obj1(:,4),obj1(:,5),obj1(:,6),obj1(:,7),...
                obj1(:,8),obj1(:,9),obj1_t(:,1),obj1_t(:,2),obj1_t(:,3),...
                filename] = textread(OptoTrackerFile,'%f %f %f %f %f %f %f %f %f %f %f %f %s');
        case 2
            [obj1(:,1),obj1(:,2),obj1(:,3),obj1(:,4),obj1(:,5),obj1(:,6),obj1(:,7),...
                obj1(:,8),obj1(:,9),obj1_t(:,1),obj1_t(:,2),obj1_t(:,3),...
                obj2(:,1),obj2(:,2),obj2(:,3),obj2(:,4),obj2(:,5),obj2(:,6),obj2(:,7),...
                obj2(:,8),obj2(:,9),obj2_t(:,1),obj2_t(:,2),obj2_t(:,3),...
                filename] = textread(OptoTrackerFile,'%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %s');
        otherwise
            disp('WARNING!!! Number of connected devices not dupported (LoadOptTrackerMotion)')
    end


    switch ObjectChooser
        case 1
            for i=1:size(obj1,1)
                if(strcmp(imagename,filename{i}(end-length(imagename)+1:end)))
                    if NumberConnected==1
                        if (~isempty(find(obj1(i,:)==50000)))
                            return
                        end
                    elseif NumberConnected==2
                        if (~isempty(find(obj1(i,:)==50000)) || ~isempty(find(obj2(i,:)==50000)))
                            return
                        end
                    end
                    arthroscope_R = [obj1(i,1),obj1(i,2),obj1(i,3);...
                        obj1(i,4),obj1(i,5),obj1(i,6);...
                        obj1(i,7),obj1(i,8),obj1(i,9)];
                    arthroscope_T = [obj1_t(i,1),obj1_t(i,2),obj1_t(i,3)];
                    break;
                end
            end;
        case 2
            for i=1:size(obj2,1)
                if(strcmp(imagename,filename{i}(end-length(imagename)+1:end)))
                    if NumberConnected==1
                        if (~isempty(find(obj1(i,:)==50000)))
                            return
                        end
                    elseif NumberConnected==2
                        if (~isempty(find(obj1(i,:)==50000)) || ~isempty(find(obj2(i,:)==50000)))
                            return
                        end
                    end
                    arthroscope_R = [obj2(i,1),obj2(i,2),obj2(i,3);...
                        obj2(i,4),obj2(i,5),obj2(i,6);...
                        obj2(i,7),obj2(i,8),obj2(i,9)];
                    arthroscope_T = [obj2_t(i,1),obj2_t(i,2),obj2_t(i,3)];
                    break;
                end
            end;
        otherwise
            disp('WARNING!!! Not a valid object number (LoadOptTrackerMotion)')
    end

    if isempty(arthroscope_R) || isempty(arthroscope_T)
        disp(sprintf('WARNING!!! No opto tracker information loaded for image %s',imagename))
    end

end


if QUAT
     
    switch NumberConnected
        case 1
            [obj1(:,1),obj1(:,2),obj1(:,3),obj1(:,4),obj1(:,5),obj1(:,6),obj1(:,7),...
                filename] = textread(OptoTrackerFile,'%f %f %f %f %f %f %f %s');
        case 2
            [obj1(:,1),obj1(:,2),obj1(:,3),obj1(:,4),obj1(:,5),obj1(:,6),obj1(:,7),...
                obj2(:,1),obj2(:,2),obj2(:,3),obj2(:,4),obj2(:,5),obj2(:,6),obj2(:,7),...
                filename] = textread(OptoTrackerFile,'%f %f %f %f %f %f %f %f %f %f %f %f %f %f %s');
        otherwise
            disp('WARNING!!! Number of connected devices not dupported (caLoadOptTrackerMotion)')
    end
    switch ObjectChooser
        case 1
            for i=1:size(obj1,1)
                if(strcmp(imagename,filename{i}(end-length(imagename)+1:end)))
                    if NumberConnected==1
                        if (~isempty(find(obj1(i,:)==50000)))
                            return
                        end
                    elseif NumberConnected==2
                        if (~isempty(find(obj1(i,:)==50000)) || ~isempty(find(obj2(i,:)==50000)))
                            return
                        end
                    end
                    arthroscope_R = quaternionToSo3([obj1(i,1) obj1(i,2) obj1(i,3) obj1(i,4)]);
                    arthroscope_T = [obj1(i,5),obj1(i,6),obj1(i,7)];
                    break;
                end
            end;
        case 2
            for i=1:size(obj2,1)
                if(strcmp(imagename,filename{i}(end-length(imagename)+1:end)))
                    if NumberConnected==1
                        if (~isempty(find(obj1(i,:)==50000)))
                            return
                        end
                    elseif NumberConnected==2
                        if (~isempty(find(obj1(i,:)==50000)) || ~isempty(find(obj2(i,:)==50000)))
                            return
                        end
                    end
                    arthroscope_R = quaternionToSo3([obj2(i,1) obj2(i,2) obj2(i,3) obj2(i,4)]);
                    arthroscope_T = [obj2(i,5),obj2(i,6),obj2(i,7)];
                    break;
                end
            end;
        otherwise
            disp('WARNING!!! Not a valid object number (caLoadOptTrackerMotion)')
    end

    if isempty(arthroscope_R) || isempty(arthroscope_T)
        disp(sprintf('WARNING!!! No opto tracker information loaded for image %s',imagename))
    end
end



