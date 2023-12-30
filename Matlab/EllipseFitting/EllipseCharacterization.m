function [index, curvature] = EllipseCharacterization(majorLength, minorLength, ellipsePoints)
    
a = majorLength;
b = minorLength;
p = ellipsePoints;

area = pi*a.*b;
h = (a-b).^2./(a+b).^2;
perimeter = pi*(a+b).*(1+(3*h)./(10+sqrt(4-3*h)));

shapeIndex = b ./ a;
compactness = 4*pi*(area./perimeter.^2);

linearEccentricity = sqrt(a.^2-b.^2);
eccentricity = linearEccentricity./a;
secondEccentricity = eccentricity./sqrt(1-eccentricity.^2);
angularEccentricity = asin(eccentricity);
flatenning = 1-cos(angularEccentricity);

semilatusRectum = a.*(1-eccentricity.^2);


index = [shapeIndex; 
    compactness; 
    linearEccentricity; 
    eccentricity; 
    secondEccentricity;
    angularEccentricity;
    flatenning;
    semilatusRectum];

if length(a) == 1
    curvature = 1/((a^.2) .* (b^.2)) .* ((p(1,:).^2/a.^4) + (p(2,:).^2/b.^4)).^(-3/2);
else
    curvature = zeros(361,length(a));
    for i = 1:length(a)
        curvature(:,i) = 1/((a(i)^2) * (b(i)^2)) .* ((p(1,:,i).^2/a(i)^4) + (p(2,:,i).^2/b(i)^4)).^(-3/2);
    end
end

end