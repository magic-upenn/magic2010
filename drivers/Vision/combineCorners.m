%combine corners that are withing a certain range

function new_corners = combineCorners(corners)

    min_dist = 5 %minimum spearation between independent corners
    for i = 1:length(corners)
        for j = 2:length(corners)-1
            dist = sqrt((corners(i,1)-corners(j,1))^2 + (corners(i,2)-corners(j,2))^2);
            if(dist < min_dist)
                new_corners