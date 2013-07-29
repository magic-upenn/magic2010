function BoldRepError(handles,ind)
for i=1:20
    if i==ind
        set(eval(sprintf('handles.rep%d',i)),'FontWeight','bold');
    else
        set(eval(sprintf('handles.rep%d',i)),'FontWeight','normal');
    end
end
drawnow