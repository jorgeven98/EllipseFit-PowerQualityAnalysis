function [centerX, centerY, majorTheta, majorLength, minorLength] = fitEllipseGAC(points)
    arguments
        points (2,:) double
    end

    Q = fitConicGAC(points);

    % Normalize GAC vector encoding ellipse
    centerY = Q / Q(3);
    
    % Extract scalar components of GAC vector
    vx = centerY(1);
    vn = centerY(2);
    v1 = centerY(4);
    v2 = centerY(5);
    vp = centerY(6);
    
    % Calculate ellipse parameters
    alpha = sqrt(vn^2+vx^2);
    cos2Theta = -vn / alpha;
    sin2Theta = -vx / alpha;
    
    % Major axis rotation angle of ellipse
    majorTheta = atan2(sin2Theta, cos2Theta) / 2;
    %majorTheta * 180 / pi;

    % Center of ellipse; should be near the origin
    center = [1-vn, vx; vx, 1-vn] \ [v1; v2];

    centerX = center(1);
    centerY = center(2);
    beta = centerX^2 + centerY^2 + (centerX^2 - centerY^2) * vn + 2 * centerX * centerY * vx - 2 * vp;
    
    % Major axis length of ellipse
    majorLength = sqrt(beta / (1 - alpha));

    % Minor axis length of ellipse
    minorLength = sqrt(beta / (1 + alpha));
end