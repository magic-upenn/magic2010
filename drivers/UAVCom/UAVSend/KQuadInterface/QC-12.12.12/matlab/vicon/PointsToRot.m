%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function [Rhat,That] = PointsToRot(m,d)

%m-(3,N) are the body frame cooridinates
%d-(3,N) are the world frame coordinates
%d = R*m + T

N = size(m,2);
dbar = sum(d,2)/N;
mbar = sum(m,2)/N;

dc = d - dbar*ones(1,N);
mc = m - mbar*ones(1,N);

%H = sum(mc*dc')
H = zeros(3,3);
for i=1:N;
    H = H + mc(:,i)*dc(:,i)';
end

%H = U*S*V'
[U,S,V] = svd(H);

Rhat = V*U';
That = dbar-Rhat*mbar;