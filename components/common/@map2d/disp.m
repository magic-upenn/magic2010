function disp(h)
% DISP Display method for the map2d object.

disp('map2d:');
disp(sprintf(' Size: %d %d', h.nx,h.ny));
disp(sprintf(' Center: (%g, %g)', h.x0, h.y0));
disp(sprintf(' Resolution: %.1f', h.resolution));
disp(sprintf(' Nshift: %d', h.nshift));
disp([' Fields:' sprintf(' "%s"', h.fields{:})]);
