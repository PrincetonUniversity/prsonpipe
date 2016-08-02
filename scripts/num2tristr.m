function s = num2tristr(n)
    if n > 99
        s = num2str(n);
    elseif n > 9
        s = ['0' num2str(n)];
    else
        s = ['00' num2str(n)];
    end
end
