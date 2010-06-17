vinit=0.5;

while(true)
    vlimit=vinit;
    if ~isempty(dangerData)
        vlimit = vinit*(min(dangerData(2,:))-robotRadius)/(dangerRadius-robotRadius);
        if vlimit<0
            vlimit=0;    
        end
    end
    SetVelocity(vlimit,0);
    pause(0.05)
end