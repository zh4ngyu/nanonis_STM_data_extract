function [cmap] = custom_color_earth()
cmap = (hot + 2*copper)/3;
cmap(1:8,:) = [];
temp = [linspace(cmap(end,1),1,9)',...
    linspace(cmap(end,2),1,9)',...
    linspace(cmap(end,3),1,9)'];
temp(1,:) = [];
cmap = [cmap;temp];


cmap = interp2(cmap,2);
cmap(:,[2,3,4,6,7,8]) = [];
end

