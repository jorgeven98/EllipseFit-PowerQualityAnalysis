function bivector = calcularBivectorNormalizado(punto1, punto2)
    % Esta función calcula el bivector normalizado a partir de dos puntos en el espacio 3D
    %
    % Entradas:
    %   punto1: Vector [x1, y1, z1] del primer punto
    %   punto2: Vector [x2, y2, z2] del segundo punto
    %
    % Salida:
    %   bivector: Objeto bivector normalizado resultante del producto exterior
    
    % Verificar entrada
    if length(punto1) ~= 3 || length(punto2) ~= 3
        error('Los puntos deben tener 3 coordenadas (x,y,z)');
    end
    
    % Convertir puntos a vectores en el álgebra geométrica
    % Si los puntos son relativos al origen, los vectores son directamente los puntos
    v1 = ga3.EncodeVector(punto1);
    v2 = ga3.EncodeVector(punto2);
    
    % Calcular el producto exterior (wedge product)
    bv = v1.op(v2);
    
    % Calcular la norma del bivector
    bv_norm = bv.norm();
    
    % Normalizar el bivector si su norma no es demasiado pequeña
    if bv_norm > 1e-10  % Umbral para evitar división por cero
        bivector = bv * (1/bv_norm);
    else
        % Si los vectores son (casi) linealmente dependientes, la norma será próxima a cero
        % warning('Los vectores son casi colineales, el bivector no está bien definido');
        bivector = bv; % Devolvemos el bivector sin normalizar
    end
    % 
    % % Mostrar información del bivector (opcional, puedes comentar estas líneas)
    % fprintf('Componentes del bivector normalizado:\n');
    % 
    % % Obtener componentes del bivector
    % components = bivector.getDataArray();
    % 
    % % Asumiendo la convención: [escalar, e1, e2, e3, e12, e23, e31, e123]
    % fprintf('  σ12 (xy): %.6f\n', components(1));
    % fprintf('  σ23 (yz): %.6f\n', components(3));
    % fprintf('  σ31 (zx): %.6f\n', -components(2));
end