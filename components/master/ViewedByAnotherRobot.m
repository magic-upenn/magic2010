function bool_val = ViewedByAnotherRobot(id, x, y)
global GPOSE GCS
% variable controlling distance to other robot to ignore
DIST_MIN = 2.0;

% get list of all other robot positions
pos_r = [];
for ids = GCS.ids
    if (ids ~=id)
        pos_r = [pos_r; GPOSE{ids}.x GPOSE{ids}.y];
    end
end

% generate matching size array of input values
pos_t = [x y];
pos_t = repmat(pos_t, [size(pos_r,1) 1] );

% compute distance to that point from supplied x, y
pos = sqrt(sum((pos_t-pos_r).^2, 2));
dist = pos(pos < DIST_MIN);

if (~isempty(dist))
    bool_val = true;
else
    bool_val = false;
end






