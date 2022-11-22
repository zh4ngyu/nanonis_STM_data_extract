function [dat] = read_dat(filePath)

fileID = fopen(filePath,'r','ieee-be');


raw = char(transpose(fread(fileID)));

dat = struct;

ind1 = strfind(raw,'X (m)');
ind2 = strfind(raw(ind1+1 : end), newline);
dat.x = str2double(raw(ind1+5 : ind1+ind2(1))) * 1e9;

ind1 = strfind(raw,'Y (m)');
ind2 = strfind(raw(ind1+1 : end), newline);
dat.y = str2double(raw(ind1+5 : ind1+ind2(1))) * 1e9;


ind1 = strfind(raw,'Start time');
ind2 = strfind(raw(ind1+1 : end), newline);
rec_date = raw(ind1+10 : ind1+ind2(1));
dat.date = [rec_date(8:11),rec_date(5:6),rec_date(2:3)];

[~,name,~] = fileparts(filePath);
dat.name = name(end-2:end);


ind1 = strfind(raw,'[DATA]');
ind2 = strfind(raw(ind1+1 : end), newline);
channel = raw(ind1+ind2(1)+1 : ind1+ind2(2)-2);
data = str2num(raw(ind1+ind2(2)+1 : end)); %#ok<*ST2NM>

dat.channel = channel;
dat.data = data;

fclose(fileID);
end

