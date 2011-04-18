mult=10;
n=90*mult;

coss = zeros(n,'single');
f = fopen('CosTable.h','w');

fprintf(f,'#include <avr/pgmspace.h>\n\n');
fprintf(f,'uint8_t COS_TABLE[%d] PROGMEM = \n{\n',(n+1)*4);
for i=0:n
    coss(i+1) = cos(i/mult*pi/180);
    bytes = typecast(coss(i+1),'uint8');
    fprintf(f,'0x%02x,0x%02x,0x%02x,0x%02x,\n',bytes);
    %fprintf(f,'0x%x,\n',coss(i+1));
end

fprintf(f,'\n};\n');

fclose(f);
