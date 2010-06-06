function h = subsample(h, n);

h.resolution = n*h.resolution;
h.nx = h.nx/n;
h.ny = h.ny/n;
h.dx = h.resolution*([0:h.nx-1] - .5*(h.nx-1));
h.dy = h.resolution*([0:h.ny-1] - .5*(h.ny-1));

for i = 1:length(h.fields),
  fname = h.fields{i};
  f0 = h.data.(fname);
  h.data.(fname) = subsample_max(f0, n);
end
