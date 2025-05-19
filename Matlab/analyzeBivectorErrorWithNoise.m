function analyzeBivectorErrorWithNoise(voltage, time, freq, reference_bivector)
    % ANALYZEBIVECTORERRWITHNOISE Analyzes bivector error vs cycle percentage for different noise levels
    %
    % Inputs:
    %   voltage - 3xN matrix with three-phase voltage samples [Va;Vb;Vc]
    %   time - 1xN vector with time samples
    %   freq - Fundamental frequency of the signal in Hz
    %   reference_bivector - Reference bivector for error calculation (ga3 object)
    
    % Define noise levels to test (standard deviation as percentage of signal amplitude)
    noise_std_levels = [0.001, 0.01, 0.02, 0.05, 0.1];
    
    % Create markers and line styles for different noise levels
    markers = {'o', 's', 'd', '^', 'v'};
    line_styles = {'-', '--', ':', '-.', '-'};
    
    % Define a professional color scheme (colorblind-friendly)
    colors = [0.0000, 0.4470, 0.7410;  % Blue
              0.8500, 0.3250, 0.0980;  % Red
              0.9290, 0.6940, 0.1250;  % Yellow
              0.4940, 0.1840, 0.5560;  % Purple
              0.4660, 0.6740, 0.1880]; % Green
    
    % Set up figure with LaTeX interpreter
    figure('Position', [100, 100, 800, 600]);
    hold on;
    
    % Configure figure for LaTeX-style
    set(gcf, 'Color', 'w');
    set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 11);
    
    % Legend labels
    plot_handles = zeros(length(noise_std_levels), 1);
    legend_entries = cell(1, length(noise_std_levels));

    % Arrays to store optimal percentages and minimum errors
    optimal_percentages = zeros(size(noise_std_levels));
    min_errors = zeros(size(noise_std_levels));
    
    % Process each noise level
    for n_idx = 1:length(noise_std_levels)
        noise_std = noise_std_levels(n_idx);
        
        % Add noise to the signal
        noisy_voltage = add_noise_to_3phase(voltage, noise_std, "std");

        % Run analysis with this noise level (without individual plots)
        result = analyzeBivectorsError(noisy_voltage, time, freq, reference_bivector, false);
        
        % Store results
        optimal_percentages(n_idx) = result.optimal_percentage;
        min_errors(n_idx) = result.minimum_error;
        
        % Plot error curve for this noise level
         plot_handles(n_idx) = plot(result.percentages, result.mean_errors, ...
             'Color', colors(n_idx,:), ...
             'LineStyle', line_styles{n_idx}, ...
             'LineWidth', 1.5);
        
        % Mark minimum error point
        % plot(result.optimal_percentage, result.minimum_error, markers{n_idx}, ...
        %      'Color', colors(n_idx,:), ...
        %      'MarkerFaceColor', colors(n_idx,:), ...
        %      'MarkerSize', 8);
        
        % Create legend entry with LaTeX formatting
        if noise_std == 0
            legend_entries{n_idx} = 'No noise';
        else
            legend_entries{n_idx} = ['$\sigma = ' sprintf('%.2f', noise_std*100) '\%$'];
        end
        
        data(:,1) = result.percentages;
        data(:,n_idx+1) = result.mean_errors;
        
        % Display result in console
        fprintf('Noise level: %.1f%%, Optimal sampling: %.1f%% of cycle (error: %.6f)\n', ...
                noise_std*100, result.optimal_percentage, result.minimum_error);
    end

    csvwrite("error_bivector_analysis.csv",data)
    
    % Finalize main plot with LaTeX styling
    %title('Bivector Error vs Percentage of Cycle', 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('Vector separation (rad)', 'Interpreter', 'latex', 'FontSize', 12);
    xticks([0 pi/2 pi 3*pi/2 2*pi]);
    xticklabels({'0','$\frac{\pi}{2}$','$\pi$','$\frac{3\pi}{2}$','2\pi$'});
    ylabel('Relative Mean Components Error (\%)', 'Interpreter', 'latex', 'FontSize', 12);
    grid on;
    box on;
    % Add legend with LaTeX interpreter
    % Add legend with explicit LaTeX interpreter setting
    legend(plot_handles, legend_entries, 'Interpreter', 'latex', 'Location', 'best', 'FontSize', 10, 'Box', 'off');
    
    % Set axis properties for LaTeX-style appearance
    ax = gca;
    ax.GridLineStyle = ':';
    ax.GridAlpha = 0.3;
    ax.LineWidth = 1;
    
    % Set axis limits
    xlim([0, 2*pi]);
    
    % Create second figure for noise impact analysis with LaTeX styling
    % figure('Position', [1000, 100, 800, 350], 'Color', 'w');
    % 
    % % Subplot 1: Optimal percentage vs noise
    % subplot(1, 2, 1);
    % plot(noise_std_levels*100, optimal_percentages, 'o-', ...
    %      'LineWidth', 1.5, 'MarkerFaceColor', colors(1,:), 'Color', colors(1,:));
    % title('Optimal Percentage vs Noise Level', 'Interpreter', 'latex', 'FontSize', 14);
    % xlabel('Noise Level (\% of signal amplitude)', 'Interpreter', 'latex', 'FontSize', 12);
    % ylabel('Optimal Percentage (\%)', 'Interpreter', 'latex', 'FontSize', 12);
    % grid on;
    % box on;
    % set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 11);
    % 
    % % Subplot 2: Minimum error vs noise
    % subplot(1, 2, 2);
    % plot(noise_std_levels*100, min_errors, 'o-', ...
    %      'LineWidth', 1.5, 'MarkerFaceColor', colors(2,:), 'Color', colors(2,:));
    % title('Minimum Error vs Noise Level', 'Interpreter', 'latex', 'FontSize', 14);
    % xlabel('Noise Level (\% of signal amplitude)', 'Interpreter', 'latex', 'FontSize', 12);
    % ylabel('Minimum Error', 'Interpreter', 'latex', 'FontSize', 12);
    % grid on;
    % box on;
    % set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 11);

end