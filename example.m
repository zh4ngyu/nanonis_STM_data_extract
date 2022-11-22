clc
clear
close all
fclose('all');

filepath = '.\2018-06-21 Gold Foil\Goldgrating_Position_Land_2_001.sxm';
[file, path] = uigetfile(filepath,'MultiSelect','on');

if ~iscell(file)
    if file == 0
        error('no file selected')
    end
    file = {file};
end






for i = 1:length(file)
    show_sxm([path, file{i}])
end








function [] = show_sxm(file)
% read .sxm file
sxm = read_sxm(file);


% display structure sxm
disp(sxm)

% x, y position data stores in sxm.x sxm.y
% z data in sxm.data{1}



% flaten
data = plane_fit(sxm.data{1});


% show image
figure
imagesc([0, sxm.range(1)], [0, sxm.range(2)], data)
set(gca,'YDir','normal')
title(sxm.compact)
pbaspect([sxm.range(1) sxm.range(2) 1])

% color map
colormap(custom_color_earth())

% color bar
colorbar
end




function data = plane_fit(data)
[nt, mt] = size(data);
avg = mean(data(:));
a = (2/nt/(nt+1) * mean(data,2)' * (1:1:nt)' - avg) * 6 / (nt-1);
b = (2/mt/(mt+1) * mean(data,1) * (1:1:mt)' - avg) * 6 / (mt-1);

data = data - a * (1:1:nt)' * ones(1,mt) - b * ones(nt,1) * (1:1:mt);
data = data - min(data(:));
end