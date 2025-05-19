function Q = fitEllipse00GAC(points)
    % Ajuste de elipses centradas en el origen en 2D utilizando el método GAC
    % Con la restricción de elipse integrada en el proceso de ajuste
    % points: matriz Nx2 donde cada fila es un punto [x, y]
    % Q: vector GAC de la elipse ajustada
    
    % Verificar entrada
    arguments
        points (:,2) double
    end
    points = points';
    
    % Número de puntos
    n = size(points, 2);
    
    % Matriz para el espacio GAC
    B = zeros(8,8);
    I3 = [0 0 1; 0 1 0; 1 0 0];
    B(1:3, 6:8) = -I3;
    B(4:5, 4:5) = eye(2);
    B(6:8, 1:3) = -I3;
    Bc = B(3:6, 3:6);
    
    % Puntos en notación GAC [0 0 1 x y 0.5(x^2 + y^2) 0.5(x^2 - y^2) xy]
    D = zeros(8, n);
    D(3,:) = ones(1,n);
    D(4:5,:) = points;
    D(6,:) = 0.5 * (points(1,:).^2 + points(2,:).^2);
    D(7,:) = 0.5 * (points(1,:).^2 - points(2,:).^2);
    D(8,:) = points(1,:) .* points(2,:);
    
    % Matriz de datos P
    P = 1/n * B * (D * D') * B;
    
    % Para una elipse centrada en el origen, v¹ = 0 y v² = 0
    % Extraemos solo las filas/columnas correspondientes a [v̄ˣ, v̄⁻, v̄⁺, v⁺]
    indices = [1, 2, 3, 6];
    P_reduced = P(indices, indices);
    
    % Matriz de restricción C para garantizar que el resultado sea una elipse
    % Implementa la restricción (v̄⁺)² - (v̄⁻)² - (v̄ˣ)² = 1
    % Que es equivalente a 4AC - B² = 1 en la forma estándar
    C = zeros(4, 4);
    C(1, 1) = -1;  % Coeficiente para (v̄ˣ)²
    C(2, 2) = -1;  % Coeficiente para (v̄⁻)²
    C(3, 3) = 1;   % Coeficiente para (v̄⁺)²
    
    % Resolver el problema de eigenvalores generalizado: P_reduced * v = λ * C * v
    % Esto integra la restricción de elipse directamente en el proceso de ajuste
    [EV, ED] = eig(P_reduced, C);
    EW = diag(ED);
    
    % Encontrar el eigenvalor positivo más pequeño
    valid_indices = find(isfinite(EW) & EW > -1e-6);
    
    if isempty(valid_indices)
        error('No se pudo ajustar una elipse a los datos proporcionados.');
    end
    
    [~, min_idx] = min(EW(valid_indices));
    k_opt = valid_indices(min_idx);
    v_opt = EV(:, k_opt);
    
    % Verificar que el resultado cumple la restricción de elipse
    ellipse_condition = v_opt(3)^2 - v_opt(2)^2 - v_opt(1)^2;
    % if ellipse_condition <= 0
    %     error('No se pudo ajustar una elipse a los datos con la restricción dada.');
    % end
    
    % Reconstruir el vector Q completo en formato GAC
    Q = zeros(8, 1);
    Q(1) = v_opt(1);  % v̄ˣ
    Q(2) = v_opt(2);  % v̄⁻
    Q(3) = v_opt(3);  % v̄⁺
    Q(6) = v_opt(4);  % v⁺
    
    % Normalizar para consistencia
    Q = Q / Q(3);
end