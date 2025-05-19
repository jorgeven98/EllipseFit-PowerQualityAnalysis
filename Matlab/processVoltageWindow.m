function [bivector_components, semiaxes, angle] = processVoltageWindow(voltage, tiempo, freq)
    % Procesa una ventana de la señal de tensión para obtener los parámetros de la elipse
    
    % Parámetros
    cycle_duration = 1/freq; % Duración de un ciclo en segundos
    n_samples = length(tiempo);
    
    % Calcular muestras por ciclo
    dt = tiempo(2) - tiempo(1);
    samples_per_cycle = round(cycle_duration / dt);
    windows_size = round(samples_per_cycle*0.25);

    % Variables
    data_size = length(1:windows_size/2:n_samples - windows_size);
    bivector_components = zeros(3,data_size);
    semiaxes = zeros(2,data_size);
    angle = zeros(1,data_size);
    j=1;

    for i = 1:windows_size/2:n_samples - windows_size

        % Extraer la ventana de datos
        voltage_window = voltage(:,i:i+windows_size);
        idx1 = 1;
        idx2= idx1 + windows_size; 
    
        % Crear vectores para calcular el bivector
        v1 = ga3.EncodeVector([voltage_window(1,idx1), voltage_window(2,idx1), voltage_window(3,idx1)]);
        v2 = ga3.EncodeVector([voltage_window(1,idx2), voltage_window(2,idx2), voltage_window(3,idx2)]);
        
        % Calcular el bivector normalizado
        bivector = v1.op(v2);
        bivector_norm = bivector.norm();
        if bivector_norm > 1e-6
            bivector_normalized = bivector/bivector_norm;
            bivector_components_pre = bivector_normalized.getDataArray;

            bivector_components(1, j) = bivector_components_pre(1);
            bivector_components(2, j) = bivector_components_pre(3);
            bivector_components(3, j) = -bivector_components_pre(2);    

        else
            warning('El bivector tiene norma muy pequeña, posiblemente vectores colineales');
            bivector_normalized(:,j) = bivector;
            bivector_components = bivector_normalized.getDataArray;

            bivector_components(1,j) = bivector_components_pre(1);
            bivector_components(2,j) = bivector_components_pre(3);
            bivector_components(3,j) = bivector_components_pre(2);
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
        [~, semiaxes(:,j), angle(j)] = extractEllipseParameters(Q);
        
        j = j + 1;
    end
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