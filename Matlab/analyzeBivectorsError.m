function result = analyzeBivectorsError(voltage, time, freq, reference_bivector, plot_results)
    % ANALYZETRIPHASESINGALBIVECTORS Analyzes the bivector error relative to a reference for different sampling distances
    %
    % Inputs:
    %   voltage - 3xN matrix with three-phase voltage samples [Va;Vb;Vc]
    %   time - 1xN vector with time samples 
    %   freq - Fundamental frequency of the signal in Hz
    %   reference_bivector - Reference bivector for error calculation (ga3 object)
    %   plot_results - Boolean flag to enable/disable plotting (default: true)
    
    if nargin < 5
        plot_results = true;
    end
    
    % Calculate cycle period and number of samples per cycle
    cycle_period = 1/freq;
    samples_per_cycle = round(cycle_period / (time(2) - time(1)));
    
    % Define percentage of cycle to analyze
    percentages = 0:1:100; % From 1% to 100% of cycle
    
    % Initialize error vector
    mean_errors = zeros(size(percentages));
    
    % Normalize reference bivector if needed
    ref_bv_norm = reference_bivector.norm();
    if abs(ref_bv_norm - 1) > 1e-6
        reference_bivector = reference_bivector * (1/ref_bv_norm);
    end
    
    % Get reference bivector components
    ref_components = abs(reference_bivector.getDataArray());
    
    % Process for each percentage
    for p_idx = 1:length(percentages)
        percent = percentages(p_idx);
        
        % Calculate sample distance based on percentage
        sample_distance = round(samples_per_cycle * percent / 100);
        
        % Skip if distance is too small
        if sample_distance < 1
            mean_errors(p_idx) = NaN;
            continue;
        end
        
        % Calculate bivectors for each valid pair of samples
        errors = [];
        
        for i = 1:(length(time) - sample_distance)
            % Create geometric vectors for the voltage samples

            bv = calcularBivectorNormalizado([voltage(1,i), voltage(2,i), voltage(3,i)],[voltage(1,i+sample_distance), voltage(2,i+sample_distance), voltage(3,i+sample_distance)]);
            
            % Extract bivector components
            components = abs(bv.getDataArray());
            
            % Calculate component-wise error (Euclidean distance in component space)
            % Assuming components 5,6,7 correspond to σ12, σ23, σ31
            component_errors = [
                100*abs(ref_components(1) - components(1))/ref_components(1),
                100*abs(ref_components(2) - components(2))/ref_components(2),
                100*abs(ref_components(3) - components(3))/ref_components(3)
            ];
            
            % Average component error
            errors = [errors, mean(component_errors)];
            
        end
        
        % Calculate mean error for this percentage
        mean_errors(p_idx) = mean(errors);
    end

    % Return results
    result.percentages = (percentages*2*pi)/100;
    result.mean_errors = mean_errors;
    
    % Find optimal percentage (minimum error)
    [min_error, min_idx] = min(mean_errors);
    result.optimal_percentage = percentages(min_idx);
    result.minimum_error = min_error;

    
    
    % Plot results if requested
    if plot_results
        figure;
        plot(percentages, mean_errors, 'LineWidth', 2);
        title('Bivector Mean Error vs Percentage of Cycle');
        xlabel('Cycle separation (rad)');
        xticks([0,pi/4,pi/2,3*pi/4,pi,5*pi/4,3*pi/2,7*pi/4,2*pi])
        xticklabels(['0','\pi/4','\pi/2','3\pi/4','\pi','5\pi/4','3\pi/2','7\pi/4','2\pi'])
        ylabel('Mean Component Error');
        grid on;

        % Display optimal result
        fprintf('Optimal sampling distance: %.1f%% of cycle (error: %.6f)\n', ...
        result.optimal_percentage, result.minimum_error);
    end
        
end