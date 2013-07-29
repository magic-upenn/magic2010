function [centro,A,B,Phi] = conic_parameters(P);

if length (P)~=6;
    error('P deve ser um vector com os seis parametros da conica...');
end

%==========================================================================
%Calculo do centro da conica

mat_center = [P(1) P(2) P(4);P(2) P(3) P(5);P(4) P(5) P(6)];
sol = [0 0 1]';
cc = inv(mat_center)*sol;
centro = [cc(1)/cc(3) cc(2)/cc(3)];
%==========================================================================

P=sign(P(1))*P;

Phi=atan((2*P(2))/(P(3)-P(1)))/2;
c=cos(Phi);
s=sin(Phi);

%==========================================================================
% Rotacao dos eixos da conica

Pr=zeros(6,1);
Pr(1)=P(1)*c*c - (2*P(2))*c*s + P(3)*s*s;
Pr(2)=2*(P(1)-P(3))*c*s + (c^2-s^2)*(2*P(2));
Pr(3)=P(1)*s*s + (2*P(2))*s*c + P(3)*c*c;
Pr(4)=(2*P(4))*c - (2*P(5))*s;
Pr(5)=(2*P(4))*s + (2*P(5))*c;
Pr(6)=P(6);
%==========================================================================
% calculo dos comprimentos dos semi-eixos da conica

F=-Pr(6) + Pr(4)^2/(4*Pr(1)) + Pr(5)^2/(4*Pr(3));
AB=sqrt(F./Pr(1:2:3));
A=AB(1);
B=AB(2);
Phi=-Phi;

if A<B % Correccoes nos angulos e exos(no caso do eixo maior nao coincidir com o eixo x)
   
    Phi=Phi-sign(Phi)*pi/2;   
    A=AB(2);
    B=AB(1);
end
