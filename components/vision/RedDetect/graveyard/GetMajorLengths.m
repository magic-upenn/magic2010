function [MajorLen,MinorLen] = GetMajorLengths(cropImCr)

    MajorLen = 0;
    MinorLen = 0;
    
        [ipix,jpix] = find(cropImCr); % co-ords of red pixels
        [eigvec,eigval] = eig(cov([ipix,jpix]));
        
        % project to 1st eigenvector
        dotprod1 = dot([ipix,jpix],repmat(eigvec(:,1)',size(ipix)),2);
        maxdot1 = max(dotprod1);
        mindot1 = min(dotprod1);
        
        proj1 = (maxdot1-mindot1)*eigvec(:,1);
        length1 = sqrt(proj1(1)^2 + proj1(2)^2);
        
        % project to 2st eigenvector
        dotprod2 = dot([ipix,jpix],repmat(eigvec(:,2)',size(ipix)),2);
        maxdot2 = max(dotprod2);
        mindot2 = min(dotprod2);
        
        proj2 = (maxdot2-mindot2)*eigvec(:,2);
        length2 = sqrt(proj2(1)^2 + proj2(2)^2);
  
        MajorLen = round(max(length1,length2));
        MinorLen = round(min(length1,length2));
        