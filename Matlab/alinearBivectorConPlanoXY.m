function rotor = alinearBivectorConPlanoXY(bivector)
    % Esta función calcula el rotor que alinea un bivector dado con el plano xy (e12)
    % utilizando operaciones de álgebra geométrica
    %
    % Entrada:
    %   bivector: Objeto bivector normalizado a alinear con el plano xy
    %
    % Salida:
    %   rotor: Objeto multivector que representa el rotor para la rotación
    
    % Primero, asegurarse de que el bivector esté normalizado
    bv_norm = bivector.norm();
    if abs(bv_norm - 1) > 1e-6
        warning('El bivector de entrada no está normalizado. Normalizando...');
        bivector = bivector * (1/bv_norm);
    end
    
    % Definir el bivector destino (plano xy)
    e12 = ga3.Multivector(2,[1 0 0]');
    
    % Calcular producto geométrica entre ambos planos
    M = e12.gp(bivector);
    
    % Extraer la parte escalar y la parte bivector normalizada
    angle = acos(-M.getScalarPart().Data);
    B = M.getBivectorPart();
    B = B/B.norm();

    % Definir el rotor 
    rotor = ga3.EncodeScalar(cos(angle/2)) - B * sin(angle/2);

    % % Verificar el resultado aplicando la rotación al bivector original
    % rotor_reverse = rotor.inverse();
    % resultado = rotor.gp(bivector).gp(rotor_reverse);
    % 
    % % Calcular el producto escalar entre el resultado y el destino
    % alignment = resultado.sp(e12);
    % 
    % fprintf('Alineación con el plano xy: %.6f (debería ser cercano a 1)\n', alignment);
    
    return;
end