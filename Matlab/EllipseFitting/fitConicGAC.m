function Q = fitConicGAC(points)
    arguments
        points (2,:) double
    end

    n = size(points, 2);

    I3 =[0 0 1; 0 1 0; 1 0 0];
    B(1:3, 6:8) = -I3;
    B(4:5, 4:5) = eye(2);
    B(6:8, 1:3) = -I3;
    Bc = B(3:6, 3:6);
    
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
    
    k_opt = find(EW == min(EW(EW>0)));
    v_opt = EV(:, k_opt);
    
    w = -P0\P1 * v_opt;
    Q = [w; v_opt];
end