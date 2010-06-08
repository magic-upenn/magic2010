function b = subsample_max(a, nsub);

[m,n] = size(a);

a1 = permute(reshape(a,[nsub m/nsub nsub n/nsub]),[1 3 2 4]);
a2 = reshape(a1,[nsub*nsub m/nsub n/nsub]);

b = squeeze(max(a2,[],1));
