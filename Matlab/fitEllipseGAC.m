function Q = fitEllipseGAC(points)
    % Ajuste de elipses en 2D utilizando el método GAC
    % points: matriz Nx2 donde cada fila es un punto [x, y]
    % Q: parámetros de la elipse ajustada en el formato [A, B, C, D, E, F]

    % Verificar entrada
    arguments
        points (:,2) double
    end
    points = points';

    % Número de puntos
    n = size(points, 2);
    
    % Matrix denoting CGA space
    I3 =[0 0 1; 0 1 0; 1 0 0];
    B(1:3, 6:8) = -I3;
    B(4:5, 4:5) = eye(2);
    B(6:8, 1:3) = -I3;
    Bc = B(3:6, 3:6);
    
    % Points in CGA notation [0 0 1 x y 0.5(x^2 + y^2) 0.5(x^2 - y^2) xy]
    D = zeros([8, n]);
    D(3,:) = ones(1,n);
    D(4:5,:) = points;
    D(6,:) = 0.5 * (points(1,:).^2 + points(2,:) .^ 2);
    D(7,:) = 0.5 * (points(1,:).^2 - points(2,:) .^ 2);
    D(8,:) = points(1,:) .* points(2,:);
    
    P = 1/n * B * (D * D') * B;
    Pc = P( 3 : 6 , 3 : 6 );
    P0 = P( 1 : 2 , 1 : 2 );
    P1 = P( 1 : 2 , 3 : 6 );
    
    Pcon = Bc * (Pc - P1' / P0 * P1);
    [EV, ED] = eig(Pcon);
    EW = diag(ED);
    % k_opt = find(EW == min(EW(EW>0)));
    % v_opt = EV(:, k_opt);

    % Paso 7 Modificado: Filtrar solo soluciones de elipse (B² - 4AC < 0)
    % valid_indices = [];
    
    [~, orden] = sort(EW(EW >= -1e-6)); indices = find(EW >= -1e-6); indices = indices(orden);    
    % disp(EW(2))
    % for i = 1:length(EW)
    %     if EW(i) >= 0
    %         v = EV(:,i);
    %         w = -P0 \ P1 * v;
    %         Q_test = [w; v];
    %         Q_test = Q_test/Q_test(3);
    % 
    %         % Extraer coeficientes de la cónica
    %         try
    %             isellipse = checkifellpise(Q_test);
    %         catch
    %             isellipse = false;
    %         end
    % 
    %         % Condición de elipse
    %         if isellipse  % Tolerancia numérica
    %             valid_indices = [valid_indices, i];
    %         end
    %     end
    % end

    for i = 1:4
        v = EV(:,indices(i));
        w = -P0 \ P1 * v;
        Q_test = [w; v];
        Q_test = Q_test/Q_test(3);

        if checkifellpise(Q_test)
            break;
        end
    end

        
    
    try
        % ellipse_eigs = EW(valid_indices);
        % idx = find(EW == min(ellipse_eigs));
        % 
        % v_opt = EV(:, idx);
        % w = -P0\P1 * v_opt;
        % Q = [w; v_opt];
        % 
        % %Normalizar el resultado (opcional, para consistencia)
        % Q = Q / Q(3);
        Q = Q_test;
    
    catch
        disp("No hay autovalores candidatos") 
        % disp(ellipse_eigs)
        % disp(min(ellipse_eigs))
    end

end



