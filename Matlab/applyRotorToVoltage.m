function transformed_voltage = applyRotorToVoltage(voltage, rotor)
    % APPLYROTORTOVOLTAGE Aplica un rotor a datos de tensión trifásica
    %
    % Inputs:
    %   voltage - Matriz 3xN con las tres fases de tensión [Va;Vb;Vc]
    %   rotor - Objeto multivector que representa el rotor (de alinearBivectorConPlanoXY)
    %
    % Output:
    %   transformed_voltage - Matriz 3xN con los datos transformados
    
    % Crear el reverso del rotor (necesario para la transformación "sandwich")
    rotor_reverse = rotor.reverse();
    
    % Obtener dimensiones
    [n_phases, n_samples] = size(voltage);
    
    % Inicializar matriz para almacenar los resultados
    transformed_voltage = zeros(size(voltage));
    
    % Procesar cada muestra de tensión
    for i = 1:n_samples
        % Convertir la muestra actual a un vector GA
        v = ga3.EncodeVector([voltage(1,i), voltage(2,i), voltage(3,i)]);
        
        % Aplicar la transformación con el rotor: v' = R v R̃
        v_transformed = rotor.gp(v).gp(rotor_reverse);
        
        % Extraer las componentes del vector transformado
        v_components = v_transformed.getDataArray();
        
        % Almacenar las componentes en la matriz resultado
        % Las componentes vectoriales deberían estar en las posiciones 2-4
        transformed_voltage(1,i) = v_components(2); % componente x
        transformed_voltage(2,i) = v_components(3); % componente y
        transformed_voltage(3,i) = v_components(4); % componente z
    end
end