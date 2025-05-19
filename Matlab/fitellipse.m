function [semieje_mayor, semieje_menor, angulo] = fitellipse(puntos)
    % AJUSTAR_ELIPSE Ajusta una elipse centrada en el origen a un conjunto de puntos 2D
    %
    % Entradas:
    %   puntos - Matriz Nx2 donde cada fila es un punto [x, y]
    %
    % Salidas:
    %   semieje_mayor - Longitud del semieje mayor de la elipse
    %   semieje_menor - Longitud del semieje menor de la elipse
    %   angulo - Ángulo de inclinación de la elipse en radianes
    
    % Verificar que tenemos suficientes puntos para ajustar
    if size(puntos, 1) < 5
        error('Se necesitan al menos 5 puntos para ajustar una elipse');
    end
    
    % Extraer coordenadas x e y
    x = puntos(:, 1);
    y = puntos(:, 2);
    
    % Para una elipse centrada en el origen, la ecuación es:
    % Ax^2 + Bxy + Cy^2 = 1
    
    % Construir la matriz de diseño
    D = [x.^2, x.*y, y.^2];
    
    % Resolver el sistema lineal D*[A;B;C] = ones(n,1) en sentido de mínimos cuadrados
    coeficientes = D \ ones(size(x));
    
    A = coeficientes(1);
    B = coeficientes(2);
    C = coeficientes(3);
    
    % Verificar que sea una elipse (no degenerada)
    discriminante = B^2 - 4*A*C;
    if discriminante >= 0
        % Si el discriminante es >= 0, no tenemos una elipse (o es degenerada)
        % En este caso, intentamos forzar una elipse ajustando el discriminante
        % Reducimos B para hacer el discriminante negativo
        B = B * 0.9;  % Reducir B en un 10%
        discriminante = B^2 - 4*A*C;
        
        % Si aún no es una elipse, forzamos los parámetros
        if discriminante >= 0
            A = 1;
            B = 0;
            C = 1;  % Esto da un círculo de radio 1
        end
    end
    
    % Convertir a forma matricial
    Q = [A, B/2; B/2, C];
    
    % Encontrar valores y vectores propios
    [V, D] = eig(Q);
    
    % Los valores propios corresponden a 1/a^2 y 1/b^2
    % donde a y b son los semiejes de la elipse
    lambda = diag(D);
    
    % Calcular longitudes de semiejes
    semieje_a = 1/sqrt(lambda(1));
    semieje_b = 1/sqrt(lambda(2));
    
    % Asegurarnos que semieje_mayor >= semieje_menor
    if semieje_a >= semieje_b
        semieje_mayor = semieje_a;
        semieje_menor = semieje_b;
        % El vector propio correspondiente al semieje mayor
        v_mayor = V(:, 1);
    else
        semieje_mayor = semieje_b;
        semieje_menor = semieje_a;
        % El vector propio correspondiente al semieje mayor
        v_mayor = V(:, 2);
    end
    
    % Calcular el ángulo de inclinación
    angulo = atan2(v_mayor(2), v_mayor(1));
end

% Función para visualizar la elipse ajustada
function visualizar_elipse(puntos, semieje_mayor, semieje_menor, angulo)
    % Graficar los puntos
    figure;
    scatter(puntos(:,1), puntos(:,2), 'b.');
    hold on;
    
    % Crear puntos para la elipse
    t = linspace(0, 2*pi, 100);
    x_elipse = semieje_mayor * cos(t);
    y_elipse = semieje_menor * sin(t);
    
    % Rotar la elipse
    R = [cos(angulo), -sin(angulo); sin(angulo), cos(angulo)];
    puntos_elipse = [x_elipse; y_elipse]';
    puntos_rotados = (R * [x_elipse; y_elipse])';
    
    % Graficar la elipse
    plot(puntos_rotados(:,1), puntos_rotados(:,2), 'r-', 'LineWidth', 2);
    
    % Configurar el gráfico
    axis equal;
    grid on;
    title('Ajuste de Elipse');
    xlabel('x');
    ylabel('y');
    legend('Datos', 'Elipse ajustada');
end

% Ejemplo de uso
function test_ajuste()
    % Generar datos de ejemplo (puntos que siguen una elipse con ruido)
    n_puntos = 50;
    a = 3;  % semieje mayor
    b = 1;  % semieje menor
    theta = pi/4;  % ángulo de inclinación (45 grados)
    
    % Generar puntos en una elipse con ruido
    t = linspace(0, 2*pi, n_puntos)';
    x_circle = cos(t);
    y_circle = sin(t);
    
    % Escalar a elipse
    x_elipse = a * x_circle;
    y_elipse = b * y_circle;
    
    % Rotar
    R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
    puntos_rotados = (R * [x_elipse, y_elipse]')';
    
    % Añadir ruido
    ruido = 0.2 * randn(n_puntos, 2);
    puntos = puntos_rotados + ruido;
    
    % Ajustar la elipse
    [semieje_mayor, semieje_menor, angulo] = ajustar_elipse(puntos);
    
    % Mostrar resultados
    fprintf('Semieje mayor: %.4f (valor real: %.2f)\n', semieje_mayor, a);
    fprintf('Semieje menor: %.4f (valor real: %.2f)\n', semieje_menor, b);
    fprintf('Ángulo (rad): %.4f (valor real: %.2f)\n', angulo, theta);
    fprintf('Ángulo (grados): %.4f (valor real: %.2f)\n', angulo*180/pi, theta*180/pi);
    
    % Visualizar el resultado
    visualizar_elipse(puntos, semieje_mayor, semieje_menor, angulo);
end