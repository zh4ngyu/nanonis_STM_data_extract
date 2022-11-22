function [tds] = read_3ds(filePath)

%read file information
fileID = fopen(filePath,'r','ieee-be');
raw = char(transpose(fread(fileID)));

file_type = read_line(raw,'Filetype=');

grid_dim = strsplit(read_line(raw,'Grid dim='),{'"','x'});
pixel = [str2double(grid_dim{2}),str2double(grid_dim{3})];

grid_set = str2num(read_line(raw,'Grid settings=')) * 1e9; %#ok<*ST2NM>

point = str2num(read_line(raw,'Points='));

channel = strsplit(str2num(read_line(raw,'Channels=')),';');

parameters = str2num(read_line(raw,'# Parameters (4 byte)='));

[~,name,~] = fileparts(filePath);
name = name(end-2:end);

rec_date = read_line(raw,'Start time=');
rec_date = [rec_date(8:11),rec_date(5:6),rec_date(2:3)];

comment = read_line(raw,'Comment=');

scan_bias = str2num(read_line(raw,'Bias>Bias (V)='));

setpoint = str2num(read_line(raw,'Z-Controller>Setpoint=')) * 1e12;

seg = str2num(read_line(raw,...
    'Segment Start (V), Segment End (V), Settling (s), Integration (s), Steps (xn)='));

if pixel(1) == 1 || pixel(2) == 1
    line_mode = true;
    data_label = {};
else
    line_mode = false;
end

if contains(file_type, 'MLS')
    bias = 0;
    for i = 1 : size(seg,1)
        bias = [bias(1:end-1),linspace(seg(i,1),seg(i,2),seg(i,5))];
    end
    
    data_label = {};
    data_label{1} = 'z';
    for i = 1 : length(bias)
        data_label{i+1} = [num2str(bias(i)*1000),'mV'];
    end
end




% move to data position
data = {};
mark = ':HEADER_END:';
ind = strfind(raw,mark);
fseek(fileID, ind + length(mark) + 1, 'bof');

%read data line by line, each point (in space) has parameters+length(channel)*point data
%first 8 parameters for grid are: start bias, end bias, x, y, z, 0, 1, NaN
%first 10 parameters for line are: 
%start bias, end bias, x, y, z, 0, setlling time, integration time, 1, NaN

y_data = [];
for j = 1 : pixel(2)
    temp = fread(fileID, [parameters+length(channel)*point, pixel(1)] ,'float');
    

    % don't know why I wrote this code, just let it be here
    if isempty(temp)
        break
    end
    
    if length(temp(5,:)) ~= pixel(1)
        break
    end
    
    y_data = [y_data, temp(4,1) * 1e9];
    

        
    if j == 1
        x_data = temp(3,:) * 1e9;
        if contains(file_type, 'Linear')
            bias = linspace(temp(1,1),temp(2,1),point);
            data_label = {};
            data_label{1} = 'z';
            for i = 1 : length(bias)
                if abs(bias(i)) < 1e-6
                    bias(i) = 0;
                end
                data_label{i+1} = [num2str(bias(i)*1000),'mV'];
            end
        end
    end
    
    
    for i = 1 : point+1
        if j == 1
            % initialize a cell
            data{i} = [];
        end
        if i == 1
            % z(tip height) data
            data{i} = [data{i};temp(5,:)]; %#ok<*AGROW>
        else
            % only pick the "Input 5[AVG]" channel data 
            % (the second channel by default, change the times of "point" to pick other channel)
            data{i} = [data{i};temp(parameters+point+i-1,:)];
        end
    end
end

tds.name = name;
tds.data = data;
tds.pixel = pixel;
tds.center = grid_set(1:2);
tds.range = grid_set(3:4);
tds.channel = channel;
tds.compact = [rec_date,' ',name,' (',...
    num2str(scan_bias),'V',', ',num2str(setpoint),'pA) ',...
    num2str(tds.range(1)),'*',num2str(tds.range(2)),'nm ',...
    comment(2:end-1)];
tds.bias = bias;
tds.label = data_label;
% tds.x = x_data - grid_set(1) + grid_set(3)/2;
% tds.y = y_data - grid_set(2) + grid_set(4)/2;
tds.x = x_data;
tds.y = y_data;

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
r = raw(ind1+length(str) : ind1+ind2(1)-3);
end

