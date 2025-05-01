%___________________TPS Dose distribution_______________________________________________

% DICOM Image Data (Dose Distribution in TPS)
dicomFilePath = 'target_1.dcm'; % TPS dose of target
dicomImage = dicomread(dicomFilePath);
I = dicominfo(dicomFilePath);

% Extract DoseGridScaling value from DICOM metadata
doseGridScaling = I.DoseGridScaling;

[rows, cols, slices, timeFrames] = size(dicomImage); % Get dimensions
centerRow = 3;
doseDistribution = squeeze(dicomImage(centerRow, :, 1, :)); % Extract data
doseDistributionFlipped = fliplr(double(doseDistribution))*doseGridScaling; 


% Actual dimensions of the original image of phantom (in cm)
Width_cm_TPS = 19.8; % in cm (original width)
Height_cm_TPS = 18.0; % in cm (original height)

% Get the number of pixels in the original Dose Distribution
[height_TPS, width_TPS] = size(doseDistributionFlipped);

% Calculate the pixel size for Dose Distribution in TPS (in cm per pixel)
pixelSizeX_TPS = Width_cm_TPS / width_TPS;  % Pixel size in X direction (cm per pixel)
pixelSizeY_TPS = Height_cm_TPS / height_TPS;  % Pixel size in Y direction (cm per pixel)

fprintf('Pixel Size for TPS (X): %.4f cm/pixel\n', pixelSizeX_TPS);
fprintf('Pixel Size for TPS (Y): %.4f cm/pixel\n', pixelSizeY_TPS);

% Visualization of Dose Distribution in TPS
figure;
imagesc([0 Width_cm_TPS], [0 Height_cm_TPS], doseDistributionFlipped'); 
colorbar;
xlabel('X-axis (cm)');
ylabel('Y-axis (cm)');
title('Dose Distribution in TPS');

% Adjust X and Y axis to be in cm
xticks(0:1:Width_cm_TPS);  % Set X ticks from 0 to 19.8 cm with step of 1 cm
yticks(0:1:Height_cm_TPS); % Set Y ticks from 0 to 18 cm with step of 1 cm
set(gca, 'XTickLabel', 0:1:Width_cm_TPS); % Ensure labels are correct and integer-based
set(gca, 'YTickLabel', 0:1:Height_cm_TPS);


%______________________Film___________________________________________

% Define the file path of Dosemap
tifFilePath = 'Plan1(1)_Dosemap.csv'; % Replace with your CSV file path

% Read the CSV file as a table
T = readtable(tifFilePath);

% Select color channel 'Red channel'
columns_R = startsWith(T.Properties.VariableNames, 'R');

% Convert to numeric array 
column_R = table2array(T(1:end, columns_R));

% Display the extracted dose intensity data
figure;
imagesc(column_R);
title('Film Dose Intensity "Red"');
axis image; % Adjust size to maintain aspect ratio
xlabel('Columns (Pixels)');
ylabel('Rows (Pixels)');

% Use colormap to represent dose intensity with color
colormap jet;  
colorbar; 


%---------------- Calibration dose map------------

% Define the file path
File_Dosemap = 'Calibration.csv'; % Replace with your CSV file path

% Read the CSV file as a table
Data_Dosemap = readtable(File_Dosemap);

% Select colume 
x = Data_Dosemap{1:100, 1};  % colume x
y1 = Data_Dosemap{1:100, 2}; % colume y1
y2 = Data_Dosemap{1:100, 3}; % colume y2
y3 = Data_Dosemap{1:100, 4}; % colume y3

% Create graph
figure;
hold on;
plot(x, y1, '-', 'DisplayName', 'Red', 'Color', 'r'); 
plot(x, y2, '-', 'DisplayName', 'Green', 'Color', 'g'); 
plot(x, y3, '-', 'DisplayName', 'Bule', 'Color', 'b'); 
hold off;

% Label X-Y axis
xlabel('X Value');
ylabel('Y Value');
title('Graph from CSV File');
legend('show'); 
grid on; 

% Defind 2 decimal
xtickformat('%.2f'); 

% Convert XTickLabel to normal numerical value
ax = gca;  % Get the current axis handle
ax.XAxis.Exponent = 0;  % Disable scientific notation (x10^n)


% ---------------- Calibration dose with intensity ----------------

% Define the file path
Plan = readtable("Plan1(1).csv");

% Select only columns 'Red channel'
columns_R_new = startsWith(Plan.Properties.VariableNames, 'R');

% Convert to numeric array
column_R_new = table2array(Plan(1:end, columns_R_new));

% Define the file path for calibration data
File_Dosemap = 'Calibration.csv'; % Replace with your CSV file path

% Read the CSV file as a table
Data_Dosemap_new = readtable(File_Dosemap);

% Select the desired columns for the graph
x_new = Data_Dosemap_new{1:100, 1};  
y1_new = Data_Dosemap_new{1:100, 2}; 

% ---------------- Interpolate to match intensity with cGy ----------------

% Interpolate the calibration data (Intensity -> cGy) for Red, Green, and Blue
cGy_R = interp1(y1_new, x_new, column_R_new(:), 'linear', 'extrap');

% ---------------- Create new Dosemap Images ----------------
% Reshape the cGy values into the image dimensions for each color channel
dosemap_R_new = reshape(cGy_R, size(column_R_new));

% ---------------- Manually Crop the Dosemap ----------------
% Display the Dosemap for Red first
figure;
imagesc(dosemap_R_new);  % Use imagesc() to normalize dose intensity data
title('Film Dosemap - Red Channel');
axis image;
xlabel('Columns (Pixels)');
ylabel('Rows (Pixels)');
colormap jet;  % Use Jet colormap to represent dose intensity
colorbar;  % Display color bar

% ---------------- Normalization of intensity ----------------

% Step 1: Calculate the minimum and maximum intensity values of both dose distributions
max_dosemap_R = max(dosemap_R_new(:));

max_doseDistributionFlipped = max(doseDistributionFlipped(:));

% Step 2: Convert the dosemap_R_new to double precision for correct arithmetic operations
dosemap_R_new_double = double(dosemap_R_new);  % Convert to double precision


% Normalize the dosemap_R_new to match the range of doseDistributionFlipped
dosemap_R_new_normalized = (dosemap_R_new_double ) / (max_dosemap_R );

% Explicit conversion of range and offset to double
range_doseDistributionFlipped = double(max_doseDistributionFlipped);

dosemap_R_new_normalized = dosemap_R_new_normalized * range_doseDistributionFlipped ;

% Step 3: Display the normalized dosemap for Red Channel
figure;
imagesc(dosemap_R_new_normalized);  % Normalized dose intensity data
title('Normalized Film Dosemap - Red Channel');
axis image;
xlabel('Columns (Pixels)');
ylabel('Rows (Pixels)');
colormap jet;  % Use Jet colormap to represent dose intensity
colorbar;  % Display color bar

% Define the real-world dimensions of the film in cm
width_cm_Film = 5.2;  % in cm
height_cm_Film = 14.2; % in cm

% Get the number of pixels in the film dosemap
[numRows_Film, numColumns_Film] = size(dosemap_R_new_normalized);

% Calculate the pixel size in cm/pixel
pixelSizeX_Film = width_cm_Film / numColumns_Film;
pixelSizeY_Film = height_cm_Film / numRows_Film;

fprintf('Pixel Size for Film (X): %.4f cm/pixel\n', pixelSizeX_Film);
fprintf('Pixel Size for Film (Y): %.4f cm/pixel\n', pixelSizeY_Film);

% Display the normalized dosemap with real-world scaling
figure;
imagesc(dosemap_R_new_normalized); % Use real-world dimensions
title('Normalized Film Dosemap - Red Channel (Scaled to cm)');
axis image;
xlabel('X-axis (cm)');
ylabel('Y-axis (cm)');
colormap jet;
colorbar;


% ---------------- Rescale TPS Dose Distribution to 0.01 cm/pixel ----------------
newHeight_TPS = round(Width_cm_TPS / 0.01);
newWidth_TPS = round(Height_cm_TPS / 0.01);

doseDistributionRescaled = imresize(doseDistributionFlipped, [newHeight_TPS, newWidth_TPS], 'nearest');
doseDistributionRescaled = doseDistributionRescaled'; 

% Display the rescaled TPS dose image
figure;
imagesc([0 Width_cm_TPS], [0 Height_cm_TPS], doseDistributionRescaled);
colorbar;
xlabel('X-axis (cm)');
ylabel('Y-axis (cm)');
title('Rescaled TPS Dose Distribution (0.01 cm/pixel)');
axis image;
colormap jet;

% Calculate the pixel size for Dose Distribution in TPS (in cm per pixel)
pixelSizeX_TPS_0_01cm = Width_cm_TPS / newWidth_TPS;  % Pixel size in X direction (cm per pixel)
pixelSizeY_TPS_0_01cm = Height_cm_TPS / newHeight_TPS;  % Pixel size in Y direction (cm per pixel)

fprintf('Pixel Size for TPS แปลงเป็น 0.01 cm/pixel (X): %.4f cm/pixel\n', pixelSizeX_TPS_0_01cm);
fprintf('Pixel Size for TPS แปลงเป็น 0.01 cm/pixel (Y): %.4f cm/pixel\n', pixelSizeY_TPS_0_01cm);

% ---------------- Rescale dosemap_R_new_normalized to 0.01 cm/pixel ----------------
% Define the real-world dimensions of the film in cm
width_cm_Film = 5.2;  % in cm
height_cm_Film = 14.2; % in cm

% Rescale the Film Dosemap to 0.01 cm per pixel
newWidth_Film = round(width_cm_Film / 0.01);
newHeight_Film = round(height_cm_Film / 0.01);

dosemap_R_new_rescaled = imresize(dosemap_R_new_normalized, [newHeight_Film, newWidth_Film], 'nearest');

% Display the rescaled Film dose image
figure;
imagesc(dosemap_R_new_rescaled);
colorbar;
xlabel('X-axis (cm)');
ylabel('Y-axis (cm)');
title('Rescaled Film Dosemap (0.01 cm/pixel)');
axis image;
colormap jet;

% Calculate the pixel size for Dose Distribution in TPS (in cm per pixel)
pixelSizeX_TPS_0_01cm = width_cm_Film / newWidth_Film;
pixelSizeY_TPS_0_01cm = height_cm_Film / newHeight_Film;

fprintf('Pixel Size for Film แปลงเป็น 0.01 cm/pixel (X): %.4f cm/pixel\n', pixelSizeX_TPS_0_01cm);
fprintf('Pixel Size for Film แปลงเป็น 0.01 cm/pixel (Y): %.4f cm/pixel\n', pixelSizeY_TPS_0_01cm);

%-------
% Define the expansion amounts (in cm)
expandLeft_cm = 1.7/0.01;  % Expand left
expandRight_cm = 3.5/0.01; % Expand right
expandBottom_cm = 8.0/0.01;   % Expand top
expandTop_cm = 6.2/0.01; % Expand bottom

% Compute the center of the image (assuming the center is at half of the width/height)
centerX_cm = (Width_cm_TPS / 2)/0.01;
centerY_cm = (Height_cm_TPS / 2)/0.01;

% Compute the four boundary coordinates (cm)
xLeft_cm = centerX_cm - expandLeft_cm;
xRight_cm = centerX_cm + expandRight_cm;
yTop_cm = centerY_cm + expandBottom_cm;
yBottom_cm = centerY_cm - expandTop_cm;

% Compute the width and height of the rectangle (cm)
rectWidth_cm = xRight_cm - xLeft_cm;
rectHeight_cm = yTop_cm - yBottom_cm;

% Draw the rectangle on the image (in cm)
figure;
imagesc(doseDistributionRescaled);
colorbar;
xlabel('X-axis (cm)');
ylabel('Y-axis (cm)');
title('Rescaled TPS Dose Distribution (0.01 cm/pixel)');
axis image;
colormap jet;
hold on;

% Correctly draw the rectangle using the computed coordinates
rectangle('Position', [xLeft_cm, yBottom_cm, rectWidth_cm, rectHeight_cm], 'EdgeColor', 'w', 'LineWidth', 2);
plot(centerX_cm, centerY_cm, 'wo', 'MarkerSize', 5, 'MarkerFaceColor', 'w'); % Center point in white

xLeft_pixel = centerX_cm - expandLeft_cm;
xRight_pixel = centerX_cm + expandRight_cm;
yTop_pixel = centerY_cm + expandBottom_cm;
yBottom_pixel = centerY_cm - expandTop_cm;

% Compute the distances from the red frame to the image edges (in cm)
distanceLeft_cm = xLeft_pixel; % Distance from the left edge
distanceRight_cm = 1800 - xRight_pixel; % Distance from the right edge
distanceTop_cm = 1980 - yTop_pixel; % Distance from the top edge
distanceBottom_cm = yBottom_pixel; % Distance from the bottom edge

% Display distances
fprintf('Distance from red frame to left edge: %.2f cm\n', distanceLeft_cm);
fprintf('Distance from red frame to right edge: %.2f cm\n', distanceRight_cm);
fprintf('Distance from red frame to top edge: %.2f cm\n', distanceTop_cm);
fprintf('Distance from red frame to bottom edge: %.2f cm\n', distanceBottom_cm);

%--------------Crop the TPS image------------------

% Convert expansion distances from cm to pixels
pixelSizeX_TPS_new = 0.01; % Assume pixel size in cm (0.01 cm/pixel)
pixelSizeY_TPS_new = 0.01;

cropAmountLeft_pixels = round(8.2 / pixelSizeX_TPS_new);
cropAmountRight_pixels = round(6.4 / pixelSizeX_TPS_new);
cropAmountBottom_pixels = round(2.8 / pixelSizeY_TPS_new);
cropAmountTop_pixels = round(1.0 / pixelSizeY_TPS_new);

% Crop the dose distribution image from all four sides
croppedDoseDistribution = doseDistributionRescaled(... 
    cropAmountBottom_pixels+1:end-cropAmountTop_pixels, ... % Crop top and bottom
    cropAmountLeft_pixels+1:end-cropAmountRight_pixels);  % Crop left and right


% Display the cropped dose distribution
figure;
imagesc(croppedDoseDistribution);
colorbar;
xlabel('X-axis (cm)');
ylabel('Y-axis (cm)');
title('Cropped Dose Distribution in TPS');

axis image; % Keep correct aspect ratio


% -------------------- Image Registration Between TPS and Film -----------------------

% Ensure both images are in double precision for better accuracy in computation
croppedDoseDistributionRescaled = double(croppedDoseDistribution);
dosemap_R_new_rescaled = double(dosemap_R_new_rescaled);


% Configure the optimizer and metric for image registration (monomodal for similar images)
[optimizer, metric] = imregconfig('monomodal');  % Configuration for intensity-based (monomodal) registration

% Perform the registration using translation (you can choose other types like rigid if needed)
tform = imregtform(dosemap_R_new_rescaled, croppedDoseDistributionRescaled, 'translation', optimizer, metric);

% Apply the transformation to the film dose map to align it with the TPS dose map
adjustedFilmDoseMapRegistered = imwarp(dosemap_R_new_rescaled, tform, 'OutputView', imref2d(size(croppedDoseDistributionRescaled)));

% Display the registered film dose map on top of the TPS dose map for comparison
figure;
imshowpair(adjustedFilmDoseMapRegistered, croppedDoseDistributionRescaled, 'montage');
colormap('jet');  % Apply color map
colorbar;

% Adjust X and Y axis ticks to display in cm for better understanding
xlabel('X-axis (cm)');
ylabel('Y-axis (cm)');
axis image; % Keep aspect ratio correct

% Print transformation parameters for further analysis or debugging
fprintf('Translation transformation parameters:\n');
disp(tform.T);

% Display cropped images in a new figure
figure;
subplot(1, 2, 1);
imshow(adjustedFilmDoseMapRegistered, []);  % Use [] to scale the display to min/max intensity
colormap('jet');  % Use a color map (jet)
colorbar;
title('Film Dose Distribution');
xlabel('X-axis (cm)');
ylabel('Y-axis (cm)');
axis image; % Keep correct aspect ratio

subplot(1, 2, 2);
imshow(croppedDoseDistributionRescaled, []);  % Use [] to scale the display to min/max intensity
colormap('jet');  % Use a color map (jet)
colorbar;
title('TPS Dose Distribution');
xlabel('X-axis (cm)');
ylabel('Y-axis (cm)');
axis image; % Keep correct aspect ratio

% Print registration transformation parameters
fprintf('Translation transformation parameters:\n');
disp(tform.T);


%________________Gamma passing rate________________________
% Adjusted images
film = adjustedFilmDoseMapRegistered;  % The EPID image (adjusted film intensity after registration)
pred = croppedDoseDistributionRescaled;  % The predicted TPS image (cropped)

%DTA = 10(3mm), 6.67(2mm), 3.33(1mm) ;  % Distance to Agreement
DTA = 10;  % Distance to Agreement in pixel 3 mm (0.1 mm/pixel)
dosed = 0.03;  % Dose threshold in percentage (3% = 0.03)
threshold = 0.2;  % Threshold for dose 10%

% Normalize both images
film = double(film); 
pred = double(pred);
film = film / max(film(:));  % Normalize EPID image to 0-1
pred = pred / max(pred(:));  % Normalize predicted image to 0-1

% Resize images to the same size (if needed)
film = imresize(film, [355 130], 'nearest');
pred = imresize(pred, [355 130], 'nearest');

% Get the size of the images
size1 = size(film);
size2 = size(pred);

% Adjust dose levels for comparison
dosed = dosed * max(film(:));  % Scaling dose threshold
maxDoseA1 = max(film(:));
maxDoseA2 = max(pred(:));
film = film / maxDoseA1;
pred = pred / maxDoseA2;

% Apply thresholding (set values below the threshold to 0)
film(film < threshold) = 0;
pred(pred < threshold) = 0;

% Initialize Gamma matrix
G = zeros(size1);
Ga = zeros(size1);

% Gamma evaluation loop (nested loops for comparing each pixel)
if size1 == size2
    for i = 1:size1(1)
        for j = 1:size1(2)
            for k = 1:size1(1)
                for l = 1:size1(2)
                    r2 = (i - k)^2 + (j - l)^2;  % Squared distance between points
                    d2 = (film(i, j) - pred(k, l))^2;  % Squared dose difference
                    Ga(k, l) = r2 / (DTA^2) + d2 / (dosed^2);  % Gamma function
                end
            end
            G(i, j) = min(min(Ga));  % Get the minimum gamma value
        end
    end
    G = sqrt(G);  % Take the square root of the gamma values

    % Save results
    save('Gamma.mat', 'G');
    
    % Compute Gamma Passing Rate (GPR)
    [x, y] = size(G);
    totalcounts = x * y;
    [bincounts] = histc(G, 0:1);
    pass = sum(sum(bincounts));  % Number of passing pixels
    GPR = 100 * pass / totalcounts;  % Gamma Passing Rate in percentage
    save('GPR.mat', 'GPR');
    
    % Compute Mean Gamma
    meanGamma = mean(G(:));
    save('meanGamma.mat', 'meanGamma');
    
    % Compute Percentile (e.g., 98th percentile)
    P = 95;  % Set percentile to 95%
    Percentile = prctile(G, P, 'all');
    save('Percentile.mat', 'Percentile');
    
    % Final Gamma results
    Gamma_results = [GPR, meanGamma, Percentile];
    save('Gamma_results.mat', 'Gamma_results');
    
else
    fprintf('Matrix size does not agree\n');
end

i;

imagesc(G);
axis image;

Row12_TPS = croppedDoseDistributionRescaled(1100,:);
Row12_Film = adjustedFilmDoseMapRegistered(1100,:);