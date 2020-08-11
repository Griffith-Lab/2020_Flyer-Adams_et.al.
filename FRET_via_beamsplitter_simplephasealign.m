function FRET_via_beamsplitter_simplephasealign()

%%%%%%%%%%%%%%%%%%%%% ASSUMPTIONS %%%%%%%%%%%%%%%%%%%%%%
% 16-bit TIFF file inputs                              %
% Vertical split between sides of the beam splitter    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set analysis parameters
CODE_REVISION_DATE = '2018-11-07';      % Code version stamp for output
BEAMSPLITTER_ALIGNMENT_FRAMES = 6;     % Number of frames to check for alignment
BASELINE_FRAMES = 60;                   % Number of baseline frames for fret ratio baseline

% Set data read paths
[~,path]=uigetfile('*.tif','Select folder of tif files');
file_names = dir(fullfile(path, '*.tif'));

%% Read in image data
fprintf(1,'Reading image data:(%03d%%)', 0); % Progress bar

first_frame = imread(fullfile(path, file_names(1).name));
frame_series = zeros(size(first_frame, 1), size(first_frame, 2), length(file_names));
frame_series(:,:,1) = first_frame;

for i = 2:length(file_names)
    fprintf(1,'\b\b\b\b\b%03d%%)', round( (i / length(file_names)) * 100)); % Progress bar

    frame_series(:,:,i) = imread(fullfile(path, file_names(i).name));
end
fprintf(1,'\n');


%% Turn the Beamsplitter Image into Two Channels

% Determine how many frames to analyze
nframes = BEAMSPLITTER_ALIGNMENT_FRAMES;
if(nframes > size(frame_series,3))
    nframes = size(frame_series,3);
end

% Randomly select that many frames from the stack
xframes = randperm(length(file_names), nframes);

% Split the images
[offset_y, offset_x] = beam_splitter_offset(xframes, frame_series);
[left, right] = split_images(frame_series, offset_y, offset_x);


%% Correct Drift in the Images
disp('Correcting for drift...');
[aligned_left, aligned_right] = align_stacks(left, right);

%% Select Signal and Background ROIs
disp('Calculating signal intensity and ratio...');
if( mean(right(:)) > mean(left(:)) )
    doodle_image = mean(aligned_right, 3);
else
    doodle_image = mean(aligned_left, 3);
end

imtemp = doodle_image/max(doodle_image(:));

figure;
imshow(imtemp);
title('Draw polygon surrounding: Background Region');
background_mask = roipoly();
close;

imtemp = imtemp - background_mask;

figure;
imshow(imtemp);
title('Draw polygon surrounding: Analysis region Of interest');
z = regionprops(background_mask, 'Centroid');
text(z.Centroid(1), z.Centroid(2), 'BG', 'Color', 'r', 'HorizontalAlignment', 'center')
signal_mask = roipoly();
close;

choice = questdlg('Draw Another ROI?','ROI Prompt','Yes','No','Yes');
while(strcmp(choice, 'Yes'))
    imtemp = imtemp - signal_mask(:,:,end);   
    figure;
    imshow(imtemp);
    title('Draw polygon surrounding: Analysis region Of interest');
    z = regionprops(background_mask, 'Centroid');
    text(z.Centroid(1), z.Centroid(2), 'BG', 'Color', 'r', 'HorizontalAlignment', 'center')
    color = get(gca,'colororder');
    for i = 1:size(signal_mask,3)
        z = regionprops(signal_mask(:,:,i), 'Centroid');
        text(z.Centroid(1), z.Centroid(2), num2str(i), ...
            'Color', color(mod(i - 1, size(color,1)) + 1,:), 'HorizontalAlignment', 'center')
    end
    signal_mask(:,:,end+1) = roipoly();
    close;
    choice = questdlg('Draw Another ROI?','ROI Prompt','Yes','No','Yes');
end
imtemp = imtemp - signal_mask(:,:,end);

%% Calculate FRET Ratio
% Calculate the mean value of the right and left channels
background_mask = double(background_mask);
background_mask_size = sum(background_mask(:));
background_left = zeros(size(aligned_left,3),1);
background_right = zeros(size(aligned_left,3),1);

signal_left = zeros(size(aligned_left,3),size(signal_mask,3));
signal_right = zeros(size(aligned_left,3),size(signal_mask,3));
corrected_left = zeros(size(aligned_left,3),size(signal_mask,3));
corrected_right = zeros(size(aligned_left,3),size(signal_mask,3));
fret = zeros(size(aligned_left,3),size(signal_mask,3));
dfret = zeros(size(aligned_left,3),size(signal_mask,3));

for j = 1:size(signal_mask,3)
    this_signal_mask = signal_mask(:,:,j);
    this_signal_mask = double(this_signal_mask);
    this_signal_mask_size = sum(this_signal_mask(:));

    for i = 1:size(aligned_right,3)
        temp = aligned_left(:,:,i) .* this_signal_mask;
        signal_left(i,j) = sum(temp(:)) / this_signal_mask_size;
    
        temp = aligned_right(:,:,i) .* this_signal_mask;
        signal_right(i,j) = sum(temp(:)) / this_signal_mask_size;
    
        temp = aligned_left(:,:,i) .* background_mask;
        background_left(i) = sum(temp(:)) / background_mask_size;
    
        temp = aligned_right(:,:,i) .* background_mask;
        background_right(i) = sum(temp(:)) / background_mask_size; 
    end
    
    corrected_left(:,j) = signal_left(:,j) - background_left;
    corrected_right(:,j) = signal_right(:,j) - background_right;

    fret(:,j) = corrected_right(:,j) ./ corrected_left(:,j);
    dfret(:,j) = (fret(:,j) - mean(fret(1:BASELINE_FRAMES,j))) / mean(fret(1:BASELINE_FRAMES,j));
end

output = struct('Analysis_Code_Version', CODE_REVISION_DATE, ...
                'Drift_Corrected_Reference_Image', doodle_image, ...
                'ROI_Mask', signal_mask, ...
                'BG_Mask', background_mask, ...
                'Left_Channel_ROI_Intensity', signal_left, ...
                'Right_Channel_ROI_Intensity', signal_right, ...
                'Left_Channel_BG_Intensity', background_left, ...
                'Right_Channel_BG_Intensity', background_right, ...
                'Ratio_Right_to_Left_BG_Subtracted', fret, ...
                'Percent_ratio_over_baseline', dfret);

%% Write the computed image sequences to disk
fprintf(1,'Writing output to disk:(%03d%%)', 0); % Progress bar
d = strfind(path, filesep);
out_fdl = strcat('Analysis_', path(d(end-1) + 1 : end - 1), '_' , datestr(now, 30) );
mkdir(out_fdl);

save(fullfile(pwd, out_fdl, 'FRET_analysis_output.mat'), 'output');
imwrite(uint16(frame_series(:,:,1)), fullfile(pwd, out_fdl, 'original_frames.tif'));
imwrite(uint16(right(:,:,1)), fullfile(pwd, out_fdl, 'right.tif'));
imwrite(uint16(left(:,:,1)), fullfile(pwd, out_fdl, 'left.tif'));
imwrite(uint16(aligned_right(:,:,1)), fullfile(pwd, out_fdl, 'aligned_right.tif'));
imwrite(uint16(aligned_left(:,:,1)), fullfile(pwd, out_fdl, 'aligned_left.tif'));

for i = 2:size(right, 3)
    fprintf(1,'\b\b\b\b\b%03d%%)', round( (i / size(right, 3)) * 100)); % Progress bar
    imwrite(uint16(frame_series(:,:,i)), fullfile(pwd, out_fdl, 'original_frames.tif'), 'WriteMode' , 'append');
    imwrite(uint16(right(:,:,i)), fullfile(pwd, out_fdl, 'right.tif'), 'WriteMode' , 'append');
    imwrite(uint16(left(:,:,i)), fullfile(pwd, out_fdl, 'left.tif'), 'WriteMode' , 'append');
    imwrite(uint16(aligned_right(:,:,i)), fullfile(pwd, out_fdl, 'aligned_right.tif'), 'WriteMode' , 'append');
    imwrite(uint16(aligned_left(:,:,i)), fullfile(pwd, out_fdl, 'aligned_left.tif'), 'WriteMode' , 'append');
end
fprintf('\n');

% Display a figure of output
figure

subplot(2, 3, [1 4])
imshow(imfuse(mean(right,3), mean(left,3)));
title('Aligned FRET Image');

subplot(2, 3, [2 5])
color = get(gca,'colororder');
imshow(imtemp);
title('ROIs Selected');
z = regionprops(background_mask, 'Centroid');
text(z.Centroid(1), z.Centroid(2), 'BG', 'Color', 'r', 'HorizontalAlignment', 'center')
for i = 1:size(signal_mask,3)
    z = regionprops(signal_mask(:,:,i), 'Centroid');
    text(z.Centroid(1), z.Centroid(2), num2str(i), ...
        'Color', color(mod(i - 1, size(color,1)) + 1,:), 'HorizontalAlignment', 'center')
end

subplot(2, 3, 3)
hold on
plot(output.Left_Channel_BG_Intensity / output.Left_Channel_BG_Intensity(1), 'color', 'magenta')
plot(output.Right_Channel_BG_Intensity / output.Right_Channel_BG_Intensity(1), 'color', 'cyan')
ylabel('Background Intensity')

subplot(2,3,6)
plot(dfret)
ylabel('delta R/R')


for j = 1:size(output.Left_Channel_ROI_Intensity,2)
    left_ROI(:,j) = output.Left_Channel_ROI_Intensity(:,j) - output.Left_Channel_BG_Intensity;
    right_ROI(:,j) = output.Right_Channel_ROI_Intensity(:,j) - output.Right_Channel_BG_Intensity;
    
    left_ROI_norm(:,j) = left_ROI(:,j)/mean(left_ROI(1:BASELINE_FRAMES,j));
    right_ROI_norm(:,j) = right_ROI(:,j)/mean(right_ROI(1:BASELINE_FRAMES,j));
end

figure;
for i = 1:size(left_ROI_norm,2)
subplot(3,5,i);
plot(left_ROI_norm(:,i),'magenta'); hold on;
plot(right_ROI_norm(:,i),'cyan'); hold on;
title(['ROI #' num2str(i)]);
end


disp('Done!');
beep

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [offset_y, offset_x] = beam_splitter_offset(xframes, frame_series)

fprintf(1,'Determining the spatial offset of the beamsplitter channels:(%03d%%)', 0); % Progress bar
[optimizer, metric] = imregconfig('multimodal');

% Find putative edges of the beamsplitter across the full stack
frame1d = sum(frame_series, 3);
frame1d = sum(frame1d, 1);
delta_frame = diff(frame1d);

% Limit the search only to the middle 50% of  the image
mask1d = zeros(size(delta_frame));
quarter_point_1d = round(size(delta_frame , 2)/4);
mask1d(quarter_point_1d:end - quarter_point_1d) = 1;
delta_frame = delta_frame .* mask1d;

[val_up, ind_up] = findpeaks(delta_frame);
[val_dn, ind_dn] = findpeaks(-delta_frame);
[~, ind_max_up] = max(val_up);
[~, ind_max_dn] = max(val_dn);

top_two = [ind_up(ind_max_up) ind_dn(ind_max_dn)];

offset = zeros(length(xframes),2);

for i = 1:length(xframes)
    fprintf(1,'\b\b\b\b\b%03d%%)', round( (i / length(xframes)) * 100)); % Progress bar
    frame = frame_series(:,:,xframes(i));
    
    % Based on the edges, create two rough images
    left = frame(:, 1:min(top_two));
    right = frame(:, max(top_two):end);
    
    % Align the images
    tform = imregtform(left , right , 'translation', optimizer, metric);
    offset(i,:) = tform.T(3,1:2);
end

peak = mean(offset);
offset_y = round(peak(2));
offset_x = round(peak(1) + max(top_two));

fprintf('\n');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [left, right] = split_images(frame_series, offset_y, offset_x)
%% Produce aligned stacks of each channel
right = [];
left = [];

fprintf(1,'Generating aligned images for ratio analysis:(%03d%%)', 0); % Progress bar

for i = 1:size(frame_series, 3)
    fprintf(1,'\b\b\b\b\b%03d%%)', round( (i / size(frame_series, 3)) * 100)); % Progress bar

    frame = frame_series(:,:,i);
    
    if(offset_y > 0)
        temp = padarray(frame, [0 abs(offset_x)], 0, 'post');
        temp = padarray(temp, [abs(offset_y) 0], 0, 'post');
        right = cat(3, right, temp);
        
        temp = padarray(frame, [0 abs(offset_x)], 0, 'pre');
        temp = padarray(temp, [abs(offset_y) 0], 0, 'pre');
        left = cat(3, left, temp);
    else
        temp = padarray(frame, [0 abs(offset_x)], 0, 'post');
        temp = padarray(temp, [abs(offset_y) 0], 0, 'pre');
        right = cat(3, right, temp);
        
        temp = padarray(frame, [0 abs(offset_x)], 0, 'pre');
        temp = padarray(temp, [abs(offset_y) 0], 0, 'post');
        left = cat(3, left, temp);
    end
end
fprintf('\n');


% Zero out areas of the image that are only present in one channel
mask = right(:,:,1) & left(:,:,1);
for i = 1:size(right, 3)
    right(:,:,i) = uint16(right(:,:,i)) .* uint16(mask);
    left(:,:,i) = uint16(left(:,:,i)) .* uint16(mask);
end

% Trim zeros
[y_top, x_left] = find(right(:,:,1), 1, 'first');
[y_bottom, x_right] = find(right(:,:,1), 1, 'last');
right = right(y_top:y_bottom, x_left:x_right, :);

[y_top, x_left] = find(left(:,:,1), 1, 'first');
[y_bottom, x_right] = find(left(:,:,1), 1, 'last');
left = left(y_top:y_bottom, x_left:x_right, :);
end


function [aligned_left, aligned_right] = align_stacks(left, right)

Rfixed = imref2d(size(right));
stack_size = size(right,3);
aligned_right = zeros(size(right));
aligned_left = zeros(size(left));
aligned_right(:,:,1) = right(:,:,1);
aligned_left(:,:,1) = left(:,:,1);


        for i = 2:stack_size
            
            tform = imregcorr(right(:,:,i) , aligned_right(:,:,1) , 'translation');
            
            aligned_right(:,:,i) = imwarp(right(:,:,i), tform, 'OutputView', Rfixed);
            aligned_left(:,:,i) = imwarp(left(:,:,i), tform, 'OutputView', Rfixed);
                   
        end

end