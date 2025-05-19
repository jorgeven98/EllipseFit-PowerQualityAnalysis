function results_table = analyzeEllipseParametersForMultipleIntensities(mat_file)
    % ANALYZEELLIPSEPARAMETERSFORMULTIPLEINTENSITIES Analiza los parámetros de elipses
    % ajustadas en señales trifásicas con diferentes intensidades de falla
    %
    % Input:
    %   mat_file - Ruta al archivo .mat que contiene todas las señales
    
    % Cargar datos
    data = load(mat_file);
    
    % Extraer campos
    tiempo = data.tiempo;
    f = data.f;               % Frecuencia del sistema
    fs = data.fs;             % Frecuencia de muestreo
    intensidad_falla = data.intensidad_falla;
    senales = data.senales;   % Matriz 3D (fase, muestra, intensidad)
    
    % Obtener dimensiones
    [n_fases, n_muestras, n_intensidades] = size(senales);
    
    % Verificar que hay tres fases
    if n_fases ~= 3
        error('Se esperan 3 fases, pero la matriz tiene %d', n_fases);
    end
    
    % Asegurar que intensidad_falla es un vector columna del tamaño correcto
    if length(intensidad_falla) ~= n_intensidades
        error('La longitud del vector intensidad_falla (%d) no coincide con el número de intensidades en la matriz senales (%d)', ...
              length(intensidad_falla), n_intensidades);
    end
    
    % Convertir intensidad_falla a vector columna si es necesario
    if size(intensidad_falla, 1) == 1
        intensidad_falla = intensidad_falla';
    end
    
    % Inicializar arrays para almacenar resultados
    major_axes = zeros(n_intensidades, 1);
    minor_axes = zeros(n_intensidades, 1);
    ellipse_angles = zeros(n_intensidades, 1);
    ellipse_ratio = zeros(n_intensidades, 1);
    e12 = zeros(n_intensidades, 1);
    e23 = zeros(n_intensidades, 1);
    e31 = zeros(n_intensidades, 1);
    
    % Procesar cada intensidad de falla
    for i = 1:n_intensidades
        % Extraer la señal trifásica para esta intensidad
        voltage = senales(:, :, i);  % Matriz 3xN (fase, muestra)
        
        % Calcular parámetros de la elipse
        [bivector_normalized, semiaxes, angle] = processVoltageWindow(voltage, tiempo, f);
        
        % Almacenar resultados
        major_axes(i) = semiaxes(1);
        minor_axes(i) = semiaxes(2);
        ellipse_angles(i) = angle;
        ellipse_ratio(i) = semiaxes(1) / semiaxes(2);
        bivector_components = bivector_normalized.getDataArray;
        e12(i) = bivector_components(1);
        e23(i) = bivector_components(3);
        e31(i) = -bivector_components(2);
        
        fprintf('Procesada intensidad %.4f: Semieje mayor: %.4f, Semieje menor: %.4f, Relación: %.4f\n', ...
                intensidad_falla(i), semiaxes(1), semiaxes(2), ellipse_ratio(i));
    end
    
    % Verificar las dimensiones antes de crear la tabla
    fprintf('Dimensiones de las variables:\n');
    fprintf('intensidad_falla: %d x %d\n', size(intensidad_falla, 1), size(intensidad_falla, 2));
    fprintf('major_axes: %d x %d\n', size(major_axes, 1), size(major_axes, 2));
    fprintf('minor_axes: %d x %d\n', size(minor_axes, 1), size(minor_axes, 2));
    fprintf('ellipse_angles: %d x %d\n', size(ellipse_angles, 1), size(ellipse_angles, 2));
    fprintf('ellipse_ratio: %d x %d\n', size(ellipse_ratio, 1), size(ellipse_ratio, 2));
    
    % Asegurarse de que todas las variables son vectores columna
    if size(intensidad_falla, 2) > 1, intensidad_falla = intensidad_falla'; end
    if size(major_axes, 2) > 1, major_axes = major_axes'; end
    if size(minor_axes, 2) > 1, minor_axes = minor_axes'; end
    if size(ellipse_angles, 2) > 1, ellipse_angles = ellipse_angles'; end
    if size(ellipse_ratio, 2) > 1, ellipse_ratio = ellipse_ratio'; end
    
    % Crear tabla de resultados
    results_table = table(intensidad_falla, e12, e23, e31, major_axes, minor_axes, ellipse_angles, ellipse_ratio);
    
    % Mostrar tabla
    disp(results_table);
    
    % Guardar tabla
    name = mat_file.extractAfter(13).erase(".mat");
    writetable(results_table, name + '_ellipse_parameters_by_intensity.csv');
    
    % Graficar resultados bivectores
    plotEllipseParameters(intensidad_falla, major_axes, minor_axes, ellipse_ratio,e12,e23,e31);
    j= length(intensidad_falla)-2;
    B = ga3.Multivector(2,[e12(j) -e31(j) e23(j)]');
    K = ga3.Multivector(2,[1/sqrt(3) -1/sqrt(3) 1/sqrt(3)]');
    visualizeBivectors([B,K]);
    hold on
    plot3(senales(1,:,j),senales(2,:,j),senales(3,:,j),"LineWidth",1, "Color","k");
end

function [bivector_normalized, semiaxes, angle] = processVoltageWindow(voltage, tiempo, freq)
    % Procesa una ventana de la señal de tensión para obtener los parámetros de la elipse
    
    % Parámetros
    cycle_duration = 1/freq; % Duración de un ciclo en segundos
    
    % Calcular muestras por ciclo
    dt = tiempo(2) - tiempo(1);
    samples_per_cycle = round(cycle_duration / dt);
    
    % Definir la ventana en la zona de falla (0.1s a 0.2s)
    fault_start_idx = find(tiempo >= 0.1, 1);
    
    % Tomar una ventana de un ciclo
    window_indices = fault_start_idx:(fault_start_idx + samples_per_cycle - 1);
    
    % Asegurarse de que no nos pasamos del tamaño de la señal
    if window_indices(end) > length(tiempo)
        window_indices = fault_start_idx:(length(tiempo) - 1);
    end
    
    % Extraer la ventana de datos
    voltage_window = voltage(:, window_indices);
    
    % Calcular índices para los vectores separados por 25% de ciclo
    quarter_cycle = round(samples_per_cycle * 0.25);
    idx1 = 1;
    idx2 = idx1 + quarter_cycle;

    % Asegurarse de que no nos pasamos del tamaño de la ventana
    if idx2 > size(voltage_window, 2)
        idx2 = size(voltage_window, 2);
    end
    
    % Crear vectores para calcular el bivector
    v1 = ga3.EncodeVector([voltage_window(1,idx1), voltage_window(2,idx1), voltage_window(3,idx1)]);
    v2 = ga3.EncodeVector([voltage_window(1,idx2), voltage_window(2,idx2), voltage_window(3,idx2)]);
    
    % Calcular el bivector normalizado
    bivector = v1.op(v2);
    bivector_norm = bivector.norm();
    if bivector_norm > 1e-10
        bivector_normalized = bivector * (1/bivector_norm);
    else
        warning('El bivector tiene norma muy pequeña, posiblemente vectores colineales');
        bivector_normalized = bivector;
    end
    
    % Obtener el rotor para alinear con el plano XY
    rotor = alinearBivectorConPlanoXY(bivector_normalized);
    
    % Aplicar el rotor a los datos de la ventana
    voltage_transformed = applyRotorToVoltage(voltage_window, rotor);
    
    % Extraer componentes X e Y para el ajuste de la elipse
    X = voltage_transformed(1,:);
    Y = voltage_transformed(2,:);
    
    % Ajustar una elipse a los datos transformados
    Q = fitEllipse00GAC([X',Y']);
    [~, semiaxes, angle] = extractEllipseParameters(Q);
end

function transformed_voltage = applyRotorToVoltage(voltage, rotor)
    % Aplica un rotor a datos de tensión trifásica
    
    % Crear el reverso del rotor
    rotor_reverse = rotor.reverse();
    
    % Obtener dimensiones
    [~, n_samples] = size(voltage);
    
    % Inicializar matriz para resultados
    transformed_voltage = zeros(size(voltage));
    
    % Procesar cada muestra
    for i = 1:n_samples
        % Convertir a vector GA
        v = ga3.EncodeVector([voltage(1,i), voltage(2,i), voltage(3,i)]);

        % Aplicar transformación
        v_transformed = rotor.gp(v).gp(rotor_reverse);
        
        % Extraer componentes
        v_components = v_transformed.getDataArray();
        
        % Almacenar componentes
        transformed_voltage(1,i) = v_components(2); % x
        transformed_voltage(2,i) = v_components(3); % y
        transformed_voltage(3,i) = v_components(4); % z
    end
end

function plotEllipseParameters(intensidad_falla, major_axes, minor_axes, ellipse_ratio, e12, e23, e31)
    % Grafica los parámetros de las elipses en función de la intensidad de falla
    
    % Asegurar que todas las variables son vectores columna
    if size(intensidad_falla, 2) > 1, intensidad_falla = intensidad_falla'; end
    if size(major_axes, 2) > 1, major_axes = major_axes'; end
    if size(minor_axes, 2) > 1, minor_axes = minor_axes'; end
    if size(ellipse_ratio, 2) > 1, ellipse_ratio = ellipse_ratio'; end
    
    figure('Position', [100, 100, 800, 700], 'Color', 'w');
    
    % Gráfica de semiejes vs. intensidad de falla
    subplot(2,1,1);
    plot(intensidad_falla, major_axes, 'ro-', 'LineWidth', 2, 'MarkerFaceColor', 'r');
    hold on;
    plot(intensidad_falla, minor_axes, 'bo-', 'LineWidth', 2, 'MarkerFaceColor', 'b');
    title('Semiejes de la elipse vs. Intensidad de falla', 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('Intensidad de falla (p.u.)', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('Longitud del semieje', 'Interpreter', 'latex', 'FontSize', 12);
    legend({'Semieje mayor', 'Semieje menor'}, 'Interpreter', 'latex', 'Location', 'best');
    grid on;
    
    % Gráfica de la relación de semiejes vs. intensidad de falla
    subplot(2,1,2);
    plot(intensidad_falla, ellipse_ratio, 'ko-', 'LineWidth', 2, 'MarkerFaceColor', 'k');
    title('Relacion de semiejes vs. Intensidad de falla', 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('Intensidad de falla (p.u.)', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('Relacion de semiejes (mayor/menor)', 'Interpreter', 'latex', 'FontSize', 12);
    grid on;
    
    % Guardar figura
    %print('ellipse_parameters_vs_intensity', '-dpdf', '-r300');
    
    % % Visualizar algunas elipses representativas (para intensidades seleccionadas)
    % figure('Position', [100, 100, 1000, 400], 'Color', 'w');
    % 
    % % Seleccionar hasta 5 intensidades representativas
    % if length(intensidad_falla) <= 5
    %     selected_indices = 1:length(intensidad_falla);
    % else
    %     % Seleccionar valores equidistantes
    %     step = (length(intensidad_falla) - 1) / 4;
    %     selected_indices = round(1:step:length(intensidad_falla));
    %     selected_indices = selected_indices(1:min(5, length(selected_indices)));
    % end
    % 
    % for i = 1:length(selected_indices)
    %     idx = selected_indices(i);
    %     a = major_axes(idx);
    %     b = minor_axes(idx);
    %     angle_rad = ellipse_angles(idx) * pi/180;
    % 
    %     subplot(1, length(selected_indices), i);
    %     plotEllipse(a, b, angle_rad);
    %     title(sprintf('Intensidad: %.2f', intensidad_falla(idx)), 'Interpreter', 'latex');
    %     axis equal;
    %     grid on;
    % end
    % 
    % % Guardar visualización de elipses
    % print('ellipse_shapes', '-dpdf', '-r300');

    % figure;
    % hold on
    % plot(e12);
    % plot(e23);
    % plot(e31);
    % plot((1/sqrt(3))*ones(length(e12)), "k");
    % legend(["e12","e23","e31"]);
end

function plotEllipse(a, b, angle)
    % Dibuja una elipse con semiejes a, b y rotación angle
    t = linspace(0, 2*pi, 100);
    x = a * cos(t);
    y = b * sin(t);
    
    % Aplicar rotación
    x_rot = x * cos(angle) - y * sin(angle);
    y_rot = x * sin(angle) + y * cos(angle);
    
    % Dibujar elipse
    plot(x_rot, y_rot, 'k-', 'LineWidth', 2);
    hold on;
    
    % Marcar los semiejes
    plot([0, a*cos(angle)], [0, a*sin(angle)], 'r-', 'LineWidth', 1.5);
    plot([0, -b*sin(angle)], [0, b*cos(angle)], 'b-', 'LineWidth', 1.5);
    
    % Ajustar ejes
    axis([-max(a,b)*1.2, max(a,b)*1.2, -max(a,b)*1.2, max(a,b)*1.2]);
    xlabel('$X$', 'Interpreter', 'latex');
    ylabel('$Y$', 'Interpreter', 'latex');
end