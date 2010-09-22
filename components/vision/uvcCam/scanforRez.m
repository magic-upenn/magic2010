function scanforRez(I);

resolutionNum = 1600;
while(resolutionNum > 0)
    if( mod(numel(imBS), resolutionNum) == 0 )
        imRS = reshape(I', resolutionNum, []);
        imagesc(imRS);
        waitforbuttonpress;
    end;
    resolutionNum = resolutionNum - 1;
end;