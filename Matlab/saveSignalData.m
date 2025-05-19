function saveSignalData(va, vb, vc, t, faultType, faultImpedance, groundImpedance)
% SAVESIGNALDATA Guarda las señales en formato compatible con pgfplots de LaTeX
%   y en archivos .mat para uso posterior
%
% Entradas:
%   va, vb, vc - Tensiones trifásicas normalizadas
%   t - Vector de tiempo [s]
%   faultType - Tipo de fallo
%   faultImpedance - Impedancia de fallo [p.u.]
%   groundImpedance - Impedancia de tierra [p.u.]

% Crear nombre de archivo base
if exist('faultImpedance', 'var') && exist('groundImpedance', 'var')
    baseFilename = sprintf('fault_%s_Zf_%.3f_Zg_%.3f', strrep(faultType, '-', '_'), faultImpedance, groundImpedance);
else
    baseFilename = sprintf('fault_%s', strrep(faultType, '-', '_'));
end

% Guardar en formato .mat
matFilename = [baseFilename '.mat'];
save(matFilename, 'va', 'vb', 'vc', 't','faultType');
fprintf('Datos guardados en archivo .mat: %s\n', matFilename);

% Guardar datos para pgfplots (formato .dat)
% 1. Formas de onda trifásicas
waveformFilename = [baseFilename '_waveforms.dat'];
waveformData = [t', va', vb', vc'];
dlmwrite(waveformFilename, waveformData, 'delimiter', '\t', 'precision', '%.6f');
fprintf('Formas de onda guardadas para pgfplots: %s\n', waveformFilename);


% Crear archivo de metadatos para referencia
metaFilename = [baseFilename '_metadata.txt'];
fid = fopen(metaFilename, 'w');
fprintf(fid, 'Fault Type: %s\n', faultType);
if exist('faultImpedance', 'var')
    fprintf(fid, 'Fault Impedance: %.3f p.u.\n', faultImpedance);
end
if exist('groundImpedance', 'var')
    fprintf(fid, 'Ground Impedance: %.3f p.u.\n', groundImpedance);
end
fprintf(fid, 'Sampling Frequency: %d Hz\n', 1/mean(diff(t)));
fprintf(fid, 'Total Duration: %.3f s\n', t(end));
fprintf(fid, 'Number of Samples: %d\n', length(t));
fprintf(fid, '\nFile Contents:\n');
fprintf(fid, '1. %s: [time, va, vb, vc]\n', [baseFilename '_waveforms.dat']);
fprintf(fid, '2. %s: MATLAB data file with all variables\n', matFilename);
fclose(fid);
fprintf('Archivo de metadatos creado: %s\n', metaFilename);

end