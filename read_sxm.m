function [sxm] = read_sxm(filePath)

fileID = fopen(filePath,'r','ieee-be');
raw = char(transpose(fread(fileID)));


% read sxm information 
ind1 = strfind(raw,':SCAN_FILE:');
ind2 = strfind(raw(ind1:end),newline);
name = raw(ind1+ind2(2)-8 : ind1+ind2(2)-6);

rec_date = read_line(raw,':REC_DATE:');
rec_date = [rec_date(8:11),rec_date(5:6),rec_date(2:3)];

pixel = str2num(read_line(raw,':SCAN_PIXELS:')); %#ok<*ST2NM>

range = str2num(read_line(raw,':SCAN_RANGE:')) * 1e9; %unit in nm

center = str2num(read_line(raw,':SCAN_OFFSET:')) * 1e9; %unit in nm

angl = str2num(read_line(raw,':SCAN_ANGLE:'));

bias = str2num(read_line(raw,':BIAS:'));

setpoint = str2num(read_line(raw,':Z-Controller>Setpoint:')) * 1e12; %unit in pA

scan_direction = read_line(raw,':SCAN_DIR:');


ind1 = strfind(raw,':DATA_INFO:');
indend = strfind(raw,':SCANIT_END:');
ind2 = strfind(raw(ind1:indend),newline);
data_info = {};
for i = 1:length(ind2)-2
    data_info = [data_info; strsplit(raw(ind1+ind2(i):ind1+ind2(i+1)))]; %#ok<*AGROW>
end




chan_num = 0;
channel = {};
for i = 1:size(data_info,1)-1
    if contains(data_info{i+1,5},'both')
        chan_num = chan_num + 2;
        channel = [channel,[data_info{i+1,3},' fwd']];
        channel = [channel,[data_info{i+1,3},' bwd']];
    else
        chan_num = chan_num + 1;
        channel = [channel,[data_info{i+1,3},' ',data_info{i+1,5}]];
    end
end




% load data, char(26)=substitute, char(4)=end of transmit
data = {};
for i = 1:chan_num
    ind = strfind(raw,':SCANIT_END:');
    fseek(fileID,ind,'bof');
    s1 = [0,0];
    while ~isequal(s1, [26,4])
        s2 = fread(fileID, 1, 'char');
        s1(1) = s1(2);
        s1(2) = s2;
    end
    
    
    % move to data position (4 Bytes per pixel)
    fseek(fileID, prod(pixel)*4*(i-1) , 0);
    data{i} = fread(fileID, pixel ,'float');
    data{i} = transpose(data{i});
    if contains(channel{i},'bwd')
        data{i} = fliplr(data{i});
    end
    
    
    
    if i == 1
        ind = isnan(data{i});
        temp = sum(ind, 2) > 0;
    end
    data{i}(temp,:) = [];
    
    
    
    if strcmp(scan_direction,'down')
        data{i} = flipud(data{i});
    end
    
    
    ind = isnan(data{i});
    temp2 = mean(data{i}(~ind));
    data{i}(ind) = temp2;
end


x_inc = range(1)/pixel(1);
y_inc = range(2)/pixel(2);

x_data = linspace(x_inc,range(1),pixel(1)) - x_inc/2;
y_data = linspace(y_inc,range(2),pixel(2)) - y_inc/2;


if strcmp(scan_direction,'down')
    y_data = flip(y_data);
end
y_data(temp) = [];
y_data = sort(y_data);







% pack
sxm = struct;


sxm.name = name;
sxm.x = x_data + center(1) - range(1)/2;
sxm.y = y_data + center(2) - range(2)/2;
sxm.center = center;
sxm.angle = angl;
sxm.range = [max(sxm.x)-min(sxm.x)+x_inc, max(sxm.y)-min(sxm.y)+y_inc];
sxm.dir = scan_direction;
sxm.inc = [x_inc, y_inc];

sxm.compact = [rec_date,'   ',name,'   (',...
    num2str(bias),'V',', ',num2str(setpoint),'pA)   ',...
    num2str(sxm.range(1)),'*',num2str(sxm.range(2)),'nm'];


sxm.data = data;
sxm.channel = channel;

fclose(fileID);
end


function r = read_line(raw,str)
ind1 = strfind(raw,str);
if isempty(ind1)
    disp(['no match: ',str])
    r = '';
    return
end
ind2 = strfind(raw(ind1:end),newline);
% newline and carriage return takes 2 char
r = raw(ind1+ind2(1) : ind1+ind2(2)-2);
end



