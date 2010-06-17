tireDiameter = 0.17;
degPerTick = 2;
tks2mtrs = degPerTick/360 * pi * tireDiameter;

sec2pts = length(encoders)/107;

i=1.5*sec2pts;
n=0;
ticks=zeros(1,27);

while i<107*sec2pts
    n=n+1;
    low=round(i-0.5*sec2pts);
    high=round(i+0.5*sec2pts);
    speed(n)=sum([encoders(3,low:high) encoders(4,low:high) encoders(5,low:high) encoders(6,low:high)])/4;
    i = i+4*sec2pts;
end

speed=speed*tks2mtrs;