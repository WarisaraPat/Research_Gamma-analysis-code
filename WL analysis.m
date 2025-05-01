% Read DICOM file   
dicomFilePath = '1.dcm';
dicomImage = dicomread(dicomFilePath);
I = dicominfo(dicomFilePath);

% Display the original image
figure('Name', 'Original Image');
imshow(dicomImage, []);

% Rotate the image by 45 degrees
rotatedImage = imrotate(dicomImage, 0, 'bilinear', 'crop');

% Display the rotated image
figure('Name', 'Rotated Image');
imshow(rotatedImage, []);

% Allow the user to interactively crop the rotated image
h = imrect;
position = wait(h);

% Crop the rotated image based on the selected region
crop1 = imcrop(rotatedImage, position);

% Display the cropped image
figure('Name', 'Crop1 Image');
imshow(crop1, []);

% Manually set the threshold value for radiation field (you can modify this value)
radiationFieldThreshold = 0.025;

% Threshold the image to create a binary mask for radiation field
binaryMaskRadiationField = imbinarize(crop1, radiationFieldThreshold);

% Display the binary mask for radiation field
figure('Name', 'Binary Mask (Radiation Field)');
imshow(binaryMaskRadiationField, []);

% Find connected components in the binary mask for radiation field
ccRadiationField = bwconncomp(binaryMaskRadiationField);
statsRadiationField = regionprops(ccRadiationField, 'BoundingBox', 'Centroid');

% Manually set the threshold value for circles (you can modify this value)
circleThreshold = 0.064;

% Adjust the object polarity for circle detection (you can modify this value)
circleObjectPolarity = 'bright'; % 'bright' or 'dark'

% Create a binary mask for circles
binaryCircle = imbinarize(crop1, circleThreshold);
figure('Name', 'Binary Mask (Circle Threshold)');
imshow(binaryCircle, []);

% Detect circles in the binary circle image
[centersCircles, radiiCircles, metricCircles] = imfindcircles(binaryCircle, [6, 20], 'ObjectPolarity', circleObjectPolarity);

% Initialize variables to store circle and square centers
circleCenters = []; % Initialize circle centers
squareCenters = []; % Initialize square centers

% Draw circles on the cropped image
figure('Name', 'Crop1 Image with Circles and Squares');
imshow(crop1, []);
hold on;
for k = 1:length(radiiCircles)
    viscircles(centersCircles(k,:), radiiCircles(k), 'EdgeColor', 'b'); % Draw blue circle
    plot(centersCircles(k,1), centersCircles(k,2), 'b.', 'MarkerSize', 10); % Draw dot at center
    circleCenters = [circleCenters; centersCircles(k,:)]; % Store center in pixels
end

% Draw squares on the cropped image
for i = 1:numel(statsRadiationField)
    bbox = statsRadiationField(i).BoundingBox;
    aspectRatio = bbox(3) / bbox(4);
    if aspectRatio >= 0.7 && aspectRatio <= 1.3
        rectangle('Position', bbox, 'EdgeColor', 'r', 'LineWidth', 2); % Draw red square
        squareCenter = statsRadiationField(i).Centroid; % Get centroid in pixels
        plot(squareCenter(1), squareCenter(2), 'r.', 'MarkerSize', 10); % Draw dot at center
        squareCenters = [squareCenters; squareCenter]; % Store center in pixels
    end
end

hold off;

% Calculate pixels per cm based on your original image dimensions
% Assuming square pixels per cm as an example; adjust as needed
pixelsPerCmX = 1190 / 40; % Example calculation for width
pixelsPerCmY = 1190 / 40; % Example calculation for height

% Calculate centers in centimeters
squareCenters_cm = squareCenters / pixelsPerCmX; % Convert square centers to cm
circleCenters_cm = circleCenters / pixelsPerCmX; % Convert circle centers to cm

% Display center coordinates on the image
for i = 1:size(squareCenters, 1)
    text(squareCenters(i, 1) + 35, squareCenters(i, 2) + 10, sprintf('Square: (%.2f, %.2f) px, (%.2f, %.2f) cm', ...
        squareCenters(i, 1), squareCenters(i, 2), squareCenters_cm(i, 1), squareCenters_cm(i, 2)), ...
        'Color', 'r', 'FontSize', 8, 'VerticalAlignment', 'bottom');
end

for k = 1:size(circleCenters, 1)
    text(circleCenters(k, 1) + 35, circleCenters(k, 2) - 10, sprintf('Circle: (%.2f, %.2f) px, (%.2f, %.2f) cm', ...
        circleCenters(k, 1), circleCenters(k, 2), circleCenters_cm(k, 1), circleCenters_cm(k, 2)), ...
        'Color', 'b', 'FontSize', 8, 'VerticalAlignment', 'bottom');
end

% Calculate distances between centers
distances = [];
for i = 1:size(squareCenters, 1)
    for j = 1:size(circleCenters, 1)
        % Calculate pixel distance
        pixelDistance = sqrt(sum((squareCenters(i,:) - circleCenters(j,:)).^2));
        distances = [distances; pixelDistance];
        
        % Convert pixel distance to centimeters
        cmDistance = pixelDistance / pixelsPerCmX; % Assume square and circle have same pixel/cm ratio
        fprintf('Distance between square %d and circle %d: %.3f pixels, %.3f cm\n', i, j, pixelDistance, cmDistance);
    end
end

% Display center coordinates
disp('Square Centers (pixels):');
disp(squareCenters);
disp('Square Centers (cm):');
disp(squareCenters_cm);

disp('Circle Centers (pixels):');
disp(circleCenters);
disp('Circle Centers (cm):');
disp(circleCenters_cm);
