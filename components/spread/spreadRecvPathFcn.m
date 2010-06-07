function spreadRecvPathFcn(msg)

global PATH

if ~isempty(msg),
  p = deserialize(msg);
  if isstruct(p),
    names = fieldnames(p);
    for i = 1:length(names),
      PATH.(names{i}) = p.(names{i});
    end
    PATH.clock = clock;
  end
end
