function ellipsePoints = getEllipsePoints(majorLength, minorLength, majorTheta, centerX, centerY, pointCount)
    arguments
        majorLength (1,1) double
        minorLength (1,1) double 
        majorTheta (1,1) double
        centerX (1,1) double
        centerY (1,1) double
        pointCount (1,1) uint32
    end

    % Angle parameter
    t = linspace(0, 2 * pi, pointCount);
    
    % Ellipse Center
    center = repmat([centerX; centerY], [1, pointCount]);
    
    % Ellipse major and minor axis unit vectors
    majorUnitVector = repmat([cos(majorTheta); sin(majorTheta)], [1, pointCount]);
    minorUnitVector = repmat([-sin(majorTheta); cos(majorTheta)], [1, pointCount]);
    
    % Ellipse points
    ellipsePoints = center + repmat(majorLength * cos(t), [2, 1]) .* majorUnitVector + repmat(minorLength * sin(t), [2, 1]) .* minorUnitVector;
    
    % Plot points
    % plot(ellipsePoints(1,:), ellipsePoints(2,:), "LineStyle","-");
end