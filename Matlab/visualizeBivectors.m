
function visualizeBivectors(bivectors)
    
    % Crear una figura para visualización
    figure;
    hold on;
    for i = 1:length(bivectors)
        % Suponiendo que tenemos un bivector genérico llamado 'bivector'
        % Por ejemplo, podría ser una combinación de los tres bivectores básicos:
        % bivector = a*σ12 + b*σ23 + c*σ31
        bivector = bivectors(i);
        
        % Convertir el bivector a su vector dual
        % En 3D, un bivector es dual a un vector
        dual_vector = bivector.dual();
        
        % Extraer las componentes vectoriales del dual
        dual_components = dual_vector.getDataArray();
        dx = dual_components(1); % Componente x
        dy = dual_components(2); % Componente y
        dz = dual_components(3); % Componente z
        
        % Calcular la magnitud
        magnitude = bivector.norm();
        
        % El vector dual al bivector representa la normal al plano
        col = parula(length(bivectors));
        quiver3(0, 0, 0, dx, dy, dz, 'LineWidth', 2, 'Color', col(i,:), 'MaxHeadSize', 0.5);
        
        % Crear un disco/plano orientado según el bivector
        % El centro del disco estará en el origen
        center = [0, 0, 0];
        
        % Normalizar el vector dual para obtener la dirección de la normal al plano
        normal = [dx, dy, dz] / sqrt(dx^2 + dy^2 + dz^2);
        
        % Crear un círculo en el plano
        r = magnitude; % Radio del círculo proporcional a la magnitud del bivector
        theta = linspace(0, 2*pi, 100);
        
        % Necesitamos generar dos vectores perpendiculares a la normal
        [v1, v2] = perpVectors(normal);
        
        % Crear puntos del círculo
        x = center(1) + r * (v1(1) * cos(theta) + v2(1) * sin(theta));
        y = center(2) + r * (v1(2) * cos(theta) + v2(2) * sin(theta));
        z = center(3) + r * (v1(3) * cos(theta) + v2(3) * sin(theta));
        

        % Dibujar el círculo
        plot3(x, y, z,'Color',col(i,:), 'LineWidth', 2);
        
        % Rellenar el círculo para mostrar el área (opcional, puede ser semitransparente)
        fill3(x, y, z,col(i,:), 'FaceAlpha', 0.3);
    end

    % Añadir elementos adicionales a la gráfica
    xlabel('x (σ_1)');
    ylabel('y (σ_2)');
    zlabel('z (σ_3)');
    title('Visualización del bivector');
    grid on;
    axis equal;
    view(3);
end

% Función para calcular vectores perpendiculares a un vector dado
function [v1, v2] = perpVectors(n)
    % n es el vector normal, y queremos encontrar v1 y v2 perpendiculares a n
    
    % Elegir un vector que no sea paralelo a n
    if abs(n(3)) < abs(n(1)) && abs(n(3)) < abs(n(2))
        v1 = [0, 0, 1];
    else
        v1 = [1, 0, 0];
    end
    
    % v1 = v1 - dot(v1, n) * n; % Hacer v1 perpendicular a n
    v1 = v1 - sum(v1 .* n) * n;
    v1 = v1 / norm(v1);
    
    % v2 = cross(n, v1); % Calcular v2 perpendicular a n y v1
    v2(1) = n(2)*v1(3) - n(3)*v1(2);
    v2(2) = n(3)*v1(1) - n(1)*v1(3);
    v2(3) = n(1)*v1(2) - n(2)*v1(1);
    
    v2 = v2 / norm(v2);
end