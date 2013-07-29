function newI = markpoints(I, points)

newI = zeros(size(I,1),size(I,2));
%make binary image with only corners
for i=1:length(points)
    newI(points(i,2),points(i,1)) = 1;
end
end