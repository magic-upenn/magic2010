%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
if(use_ipc)
    sipcm = ipcAPIReceive(1);
    if ~isempty(sipcm)
        for jj=1:size(sipcm,1)
            %  if(use_linux)
            if(strcmp(sipcm(jj).name,'seqmsg'))
                handleipc
                disp(sprintf('Message received:'));
            end
            if(strcmp(sipcm(jj).name,'KillSwitch'))
                killflag = 1;
                fprintf('Killing now\n');
            end
            if(startflag==0)
                if(strcmp(sipcm(jj).name,'StartSwitch'))
                    startflag = 1;
                    killflag = 0;
                    fprintf('Starting now\n');
                end
            end
        end
    end
end