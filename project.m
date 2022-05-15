clc;
close all;
clear all;
fontSize = 20;  % Font size for image captions.
startingFolder = 'C:\Users\asus\Desktop\mazeimages';
if ~exist(startingFolder, 'dir')
    
    startingFolder = pwd;
end
 
continueWithAnother = true;
promptMessage = sprintf('Please specify a maze image (in the next window).\nThis program will attempt to solve the maze using mathematical morphology.');
button = questdlg(promptMessage, 'maze_solution_final', 'OK', 'Cancel', 'OK');
if strcmpi(button, 'Cancel')
    continueWithAnother = false;
end
 
while continueWithAnother
    % Get the name of the maze image file that the user wants to use.
    defaultFileName = fullfile(startingFolder, '*.*');
    [baseFileName, folder] = uigetfile(defaultFileName, 'Select maze image file');
    if baseFileName == 0
        % User hit cancel.  Bail out.
        return;
    end
    fullFileName = fullfile(folder, baseFileName);
    
    tic
    
    
    % Open the maze image file.
    originalImage = imread(fullFileName);
    [~, ~, numberOfColorBands] = size(originalImage);
    
    % Convert to monochrome for processing.
    if numberOfColorBands > 1
        % Convert to monochrome.
        redPlane = originalImage(:, :, 1);
        greenPlane = originalImage(:, :, 2);
        bluePlane = originalImage(:, :, 3);
        % Find the standard deviation of each color channel.
        redStdDev = std(single(redPlane(:)));
        greenStdDev = std(single(greenPlane(:)));
        blueStdDev = std(single(bluePlane(:)));
        % Take the color channel with the highest contrast.
        % Transfer it into a monochrome image.  This will be the one that we use.
        if redStdDev >= greenStdDev && redStdDev >= blueStdDev
            % Red has most contrast - use that channel.
            monoImage = single(redPlane);
        elseif greenStdDev >= redStdDev && greenStdDev >= blueStdDev
            % Green has most contrast - use that channel.
            monoImage = single(greenPlane);
        else
            % Blue has most contrast - use that channel.
            monoImage = single(bluePlane);
        end
    else
        monoImage = single(originalImage);
    end
    % Now we have a monochrome image that we can use to solve the maze.
    % Display the results of this step.
    close all;  % Close any prior windows that are open from a prior run.
    subplot(2, 2, 1);
    imshow(monoImage, []);
    title('Original Image', 'FontSize', fontSize);
    set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
    
    % Scale image to 0-255.
    maxValue = max(max(monoImage));
    minValue = min(min(monoImage));
    monoImage = uint8(255 * (single(monoImage) - minValue) / (maxValue - minValue));
    % Threshold to get the walls.  This will also sharpen up blurry, fuzzy wall edges.
    thresholdValue = uint8((maxValue + minValue) / 2);
    binaryImage = 255 * (monoImage < thresholdValue);
    % Display the results of this step.
    subplot(2, 2, 2);
    imshow(binaryImage, []);
    title('Binary Image - The walls are white here, instead of black', 'FontSize', fontSize);
    
    % Label the image to identify discrete, separate walls.
    [labeledImage, numberOfWalls] = bwlabel(binaryImage, 4);     % Label each blob so we can make measurements of it
    coloredLabels = label2rgb (labeledImage, 'hsv', 'k', 'shuffle'); % pseudo random color labels
    % Display the results of this step.
    subplot(2, 2, 3);
    imshow(coloredLabels);
    caption = sprintf('Labeled image of the %d walls, each a different color', numberOfWalls);
    title(caption, 'FontSize', fontSize);
    if numberOfWalls ~= 2
        message = sprintf('This is not a "perfect maze" with just 2 walls.\nThis maze appears to have %d walls,\nso you may get unexpected results.', numberOfWalls);
        uiwait(msgbox(message));
    end
    
    
    binaryImage2 = (labeledImage == 1);
    % Display the results of this step.
    subplot(2, 2, 4);
    imshow(binaryImage2, []);
    title('One of the walls', 'FontSize', fontSize);
     %% num of borders
    [Rows,Columns]=size(binaryImage);
  
    j=0;
    k=0;
    l=0;
    for i=1:Rows
        if(sum(binaryImage(i,:))/255<10)
            j=j+1;
        else
            break;
        end
    end
    for i=1:Columns
        if(sum(binaryImage(:,i))/255<10)
            k=k+1;
        else
            break;
        end
    end
    for i=Columns:-1:1
        if(sum(binaryImage(:,i))/255<10)
            l=l+1;
        else
            break;
        end
    end
   
        
    % Specifying the num of dilation or erotion
   binaryImage3=binaryImage(j+1:Rows,k+1:Columns-1-l);
    cnt=0;
  [Rows,Columns]=size(binaryImage3);  
    
    for i=1:Columns-1
        if binaryImage3(1,i)==0
            cnt=cnt+1;
        end
        if cnt~=0 && binaryImage3(1,i)==255
            break;
        end
    end
    
    if cnt==0
        for i=1: Rows-1
            if binaryImage3(i,1)==0
                cnt=cnt+1;
            end
            if cnt~=0 && binaryImage3(i,1)==255
                break;
            end
        end
    end
    
    if cnt==0
        for i=1:Rows-1
            if binaryImage3(i,Columns)==0
                cnt=cnt+1;
            end
            if cnt~=0 && binaryImage3(i,Columns)==255
                break;
            end
        end
    end
    binaryImage3
    
    
    DE_n=cnt;
   
   
    %%
    
    % Dilate the walls by a few pixels
    dilationAmount = 2*DE_n-1; % Number of pixels to dilate and erode
    % IMPORTANT NOTE: dilationAmount is a parameter that we may
    % wish to experiment with, trying different integer values.
    dilatedImage = imdilate(binaryImage2, ones(dilationAmount));
    
    figure;  % Create another, new figure window.
    set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
    % Display the results of this step.
    subplot(2, 2, 1);
    imshow(dilatedImage, []);
    title('Dilation of one wall', 'FontSize', fontSize);
    
    filledImage = imfill(dilatedImage, 'holes');
    % Display the results of this step.
    subplot(2, 2, 2);
    imshow(filledImage, []);
    title('Now filled to get rid of holes', 'FontSize', fontSize);
    
    % Erode by the same amount of pixels
    erodedImage = imerode(filledImage, ones(dilationAmount));
    % Display the results of this step.
    subplot(2, 2, 3);
    imshow(erodedImage, []);
    title('Eroded', 'FontSize', fontSize);
    
    % Set the eroded part to zero to find the difference.
   
    solution = filledImage;
    solution(erodedImage) = 0;
    % Display the results of this step.
    subplot(2, 2, 4);
    imshow(solution, []);
    title('The Difference = The Solution', 'FontSize', fontSize);
    
    % Put the solution in red on top of the original image
    if numberOfColorBands == 1
        % If we're monochrome, we need to make the color planes.
        % If we're color, we already have these from above.
        redPlane = monoImage;
        greenPlane = monoImage;
        bluePlane = monoImage;
    end
    redPlane(solution) = 0;
    greenPlane(solution) = 255;
    bluePlane(solution) = 0;
    solvedImage = cat(3, redPlane, greenPlane, bluePlane);
    % Display the results of this step.
    figure;  % Create another, new figure window.
    imshow(solvedImage);
    set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
    title('Final Solution Over Original Image', 'FontSize', fontSize);
    toc
    %   Ask if we want to solve another maze.
    promptMessage = sprintf('Do you want to solve another maze?');
    button = questdlg(promptMessage, 'maze_solution', 'Yes', 'No', 'No');
    if strcmpi(button, 'No')
        continueWithAnother = false;
    end
    binaryImage
end




