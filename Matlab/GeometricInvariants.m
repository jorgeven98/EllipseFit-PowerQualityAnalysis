function [u,k1,k2,t] = GeometricInvariants(v1,v2,v3,varargin)
    p = inputParser;
    tend = 0;
    tstep = 0.0001;
    simplier = false;

    addOptional(p,'tend',tend,@(x) x>0);
    addOptional(p,'tstep',tstep,@(x) x>=0.0001);
    addOptional(p,'simplier',simplier,@(x) x==true || x == false);

    parse(p,varargin{:});

    tend = p.Results.tend;
    tstep = p.Results.tstep;
    simplier = p.Results.simplier;

    u = [v1,v2,v3];
    up = diff(u);
    upp = diff(u,2);
    uppp = diff(u,3);
    
    % Curvature
    k = norm(cross(up,upp))./norm(up).^3;
    %Torsion
    tau = -dot(up,cross(upp,uppp))/norm(cross(up,upp))^2;
    
    k1 = norm(up)*k;
    k2 = norm(up)*tau;

    if simplier 
        % Curvature simplify
        k_s = norm(cross(u,up))./norm(u).^3;
        %Torsion simplify
        tau_s = -dot(u,cross(up,upp))/norm(cross(u,up))^2;
    
        k1 = [k1, norm(u)*k_s];
        k2 = [k2, norm(u)*tau_s];
    end


    if tend~=0 && tend>2*tstep
        t = (0:tstep:tend)';
        u = eval(subs(u));
        k1 = eval(subs(k1));
        k2 = eval(subs(k2));
    end

end

