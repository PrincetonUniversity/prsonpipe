function s = num2dubstr(n)
if n > 9
        s = num2str(n);
    else
        s = ['0' num2str(n)];
end
end