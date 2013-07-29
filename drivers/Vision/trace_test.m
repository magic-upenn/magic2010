for k = 1:length(boundaries)
bound = boundaries{k};
if length(bound) < 100
    continue;
end
hold on;
plot(bound(:,2), bound(:,1), 'b', 'LineWidth', 2);
end
