function analyzeEllipseParameters(files_pattern)
    % ANALYZEELLIPSEPARAMETERS Analiza los parámetros de elipses ajustadas en señales trifásicas
    % con fallas tras alinear el bivector con el plano XY
    %
    % Input:
    %   files_pattern - Patrón para buscar archivos .mat (e.j. 'A-G_*.mat')
    
    % Encontrar todos los archivos que coinciden con el patrón
    files = dir(files_pattern);
    
    if isempty(files)
        error('No se encontraron archivos que coincidan con el patrón.');
    end
    
    % Inicializar arrays para almacenar resultados
    num_files = length(files);
    fault_names = cell(num_files, 1);
    fault_angles = zeros(num_files, 1);
    major_axes = zeros(num_files, 1);
    minor_axes = zeros(num_files, 1);
    ellipse_angles = zeros(num_files, 1);
    
    % Procesar cada archivo
    for i = 1:num_files
        % Cargar datos
        data = load(fullfile(files(i).folder, files(i).name));
        
        % Extraer nombre de la falla
        fault_names{i} = data.faultType;
        
        % Extraer ángulo de la falla (grados) del nombre
        angle_str = regexp(fault_names{i}, '_POW_(\d+)', 'tokens');
        if ~isempty(angle_str)
            fault_angles(i) = str2double(angle_str{1}{1});
        else
            fault_angles(i) = NaN;
        end
        
        % Extraer las señales de tensión y tiempo
        va = data.va;
        vb = data.vb;
        vc = data.vc;
        t = data.t;
        
        % Combinar en una matriz 3xN
        voltage = [va; vb; vc];
        
        % Calcular parámetros de la elipse
        [center, semiaxes, angle] = processVoltageWindow(voltage, t);
        
        % Almacenar resultados
        major_axes(i) = semiaxes(1);
        minor_axes(i) = semiaxes(2);
        ellipse_angles(i) = angle;
        
        fprintf('Procesado: %s, Semieje mayor: %.4f, Semieje menor: %.4f\n', ...
                fault_names{i}, semiaxes(1), semiaxes(2));
    end
    
    % Ordenar resultados por ángulo de falla
    [fault_angles, sort_idx] = sort(fault_angles);
    fault_names = fault_names(sort_idx);
    major_axes = major_axes(sort_idx);
    minor_axes = minor_axes(sort_idx);
    ellipse_angles = ellipse_angles(sort_idx);
    
    % Crear tabla de resultados
    results_table = table(fault_names, fault_angles, major_axes, minor_axes, ellipse_angles);
    
    % Mostrar tabla
    disp(results_table);
    
    % Guardar tabla
    writetable(results_table, 'ellipse_parameters.csv');
    
    % Graficar resultados
    plotEllipseParameters(fault_angles, major_axes, minor_axes);
end

function [center, semiaxes, angle] = processVoltageWindow(voltage, t)
    % Procesa una ventana de la señal de tensión para obtener los parámetros de la elipse
    
    % Parámetros
    freq = 50; % Frecuencia en Hz
    cycle_duration = 1/freq; % Duración de un ciclo en segundos
    
    % Calcular muestras por ciclo
    dt = t(2) - t(1);
    samples_per_cycle = round(cycle_duration / dt);
    
    % Definir la ventana en la zona de falla (0.1s a 0.2s)
    fault_start_idx = find(t >= 0.1, 1);
    
    % Tomar una ventana de un ciclo
    window_indices = fault_start_idx:(fault_start_idx + samples_per_cycle - 1);
    
    % Extraer la ventana de datos
    voltage_window = voltage(:, window_indices);
    t_window = t(window_indices);
    
    % Calcular índices para los vectores separados por 25% de ciclo
    quarter_cycle = round(samples_per_cycle * 0.25);
    idx1 = 1;
    idx2 = idx1 + quarter_cycle;
    
    % Crear vectores para calcular el bivector
    v1 = ga3.EncodeVector([voltage_window(1,idx1), voltage_window(2,idx1), voltage_window(3,idx1)]);
    v2 = ga3.EncodeVector([voltage_window(1,idx2), voltage_window(2,idx2), voltage_window(3,idx2)]);
    
    % Calcular el bivector normalizado
    bivector = v1.op(v2);
    bivector_norm = bivector.norm();
    if bivector_norm > 1e-6
        bivector_normalized = bivector * (1/bivector_norm);
    else
        error('El bivector tiene norma muy pequeña');
    end
    
    % Obtener el rotor para alinear con el plano XY
    rotor = alinearBivectorConPlanoXY(bivector_normalized);
    
    % Aplicar el rotor a los datos de la ventana
    voltage_transformed = applyRotorToVoltage(voltage_window, rotor);
    
    % Extraer componentes X e Y para el ajuste de la elipse
    X = voltage_transformed(1,:);
    Y = voltage_transformed(2,:);
    
    % Ajustar una elipse a los datos transformados
    Q = fitEllipseGAC([X',Y']);
    [center, semiaxes, angle] = extractEllipseParameters(Q);
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

function plotEllipseParameters(fault_angles, major_axes, minor_axes)
    % Grafica los parámetros de las elipses en función del ángulo de falla
    
    figure('Position', [100, 100, 1000, 600], 'Color', 'w');
    
    % Gráfica de semiejes vs. ángulo de falla
    subplot(2,1,1);
    plot(fault_angles, major_axes, 'ro-', 'LineWidth', 2, 'MarkerFaceColor', 'r');
    hold on;
    plot(fault_angles, minor_axes, 'bo-', 'LineWidth', 2, 'MarkerFaceColor', 'b');
    title('Semiejes de la elipse vs. Angulo de falla', 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('Angulo de falla (grados)', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('Longitud del semieje', 'Interpreter', 'latex', 'FontSize', 12);
    legend({'Semieje mayor', 'Semieje menor'}, 'Interpreter', 'latex', 'Location', 'best');
    grid on;
    
    % Gráfica de la relación de semiejes vs. ángulo de falla
    subplot(2,1,2);
    ratio = major_axes ./ minor_axes;
    plot(fault_angles, ratio, 'ko-', 'LineWidth', 2, 'MarkerFaceColor', 'k');
    title('Relación de semiejes vs. Angulo de falla', 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('Angulo de falla (grados)', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('Relacion de semiejes (mayor/menor)', 'Interpreter', 'latex', 'FontSize', 12);
    grid on;
    
    % Guardar figura
    print('ellipse_parameters_vs_fault_angle', '-dpdf', '-r300');
end