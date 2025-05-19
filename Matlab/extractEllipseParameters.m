function [center, axes, angle] = extractEllipseParameters(Q)

    % Extract scalar components of GAC vector
    vx = Q(1);
    vn = Q(2);
    v1 = Q(4);
    v2 = Q(5);
    vp = Q(6);

    % Calculate ellipse parameters
    alpha = sqrt(vn^2+vx^2);
    cos2Theta = -vn / alpha;
    sin2Theta = -vx / alpha;
    
    % Major axis rotation angle of ellipse
    angle = atan2(sin2Theta, cos2Theta) / 2;
    %majorTheta * 180 / pi;

    % Center of ellipse; should be near the origin
    % center = [1+vn, vx; vx, 1-vn] \ [v1; v2];
    center = inv([1+vn, vx; vx, 1-vn])*[v1; v2];

    centerX = center(1);
    centerY = center(2);
    beta = centerX^2 + centerY^2 + (centerX^2 - centerY^2) * vn + 2 * centerX * centerY * vx - 2 * vp;
    
    % Major axis length of ellipse
    rM = sqrt(beta / (1 - alpha));

    % Minor axis length of ellipse
    rm = sqrt(beta / (1 + alpha));

    axes = [rM, rm];

    if (rM - rm)/rM < 1e-3
        angle = 0;
    end
    if angle < 0
        angle = angle + pi;
    end
end