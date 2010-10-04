function ListOfNotCovered = NotViewedByAnotherRobot(id, x, y)
global GPOSE GCS
% variable controlling distance to other robot to ignore
DIST_MIN = 1.0;

[x n] = shiftdim(x);
[y n] = shiftdim(y);


t_size = size(x,1);

% get list of all other robot positions
pos_r = [];
for ids = GCS.ids
    if (ids ~=id && ~isempty(GPOSE{ids}))
        pose = repmat([GPOSE{ids}.x GPOSE{ids}.y], [t_size, 1]);
        pos_r = [pos_r; pose];
    end
end

if isempty(pos_r)
  ListOfNotCovered = ones(t_size);
  return;
end

% generate matching size array of input values
%pos_t = [x y];
pos_t = repmat([x y], [size(pos_r,1)/t_size 1] );

% compute distance to that point from supplied x, y
% diff = pos_t-pos_r;

pos = sqrt(sum((pos_t-pos_r).^2, 2));
pos = reshape(pos, t_size, []); 
pos = min(pos,[], 2);
ListOfNotCovered = (pos > DIST_MIN);
% 
% if (~isempty(dist))
%     bool_val = true;
% else
%     bool_val = false;
% end






