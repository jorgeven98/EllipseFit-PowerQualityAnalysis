function senales_filtradas = filtrar_ruido(senales, fs, metodo, parametros)
% FILTRAR_RUIDO Filtra el ruido de una o varias señales utilizando diferentes métodos
%
% Entradas:
%   senales - Matriz donde cada columna es una señal a filtrar, o un vector
%             para una sola señal
%   fs - Frecuencia de muestreo en Hz
%   metodo - Método de filtrado ('pasabajas', 'pasabanda', 'media_movil', 
%            'mediana', 'wavelet', 'kalman')
%   parametros - Estructura con parámetros específicos del método elegido
%
% Salida:
%   senales_filtradas - Matriz donde cada columna es una señal filtrada
%
% Ejemplos de uso:
%   % Filtrar una señal
%   parametros.frecuencia_corte = 60; % Hz
%   senal_filtrada = filtrar_ruido(senal, fs, 'pasabajas', parametros);
%
%   % Filtrar varias señales
%   % senales es una matriz donde cada columna es una señal diferente
%   parametros.frecuencia_baja = 45; % Hz
%   parametros.frecuencia_alta = 55; % Hz
%   senales_filtradas = filtrar_ruido(senales, fs, 'pasabanda', parametros);


% Verificar entradas
senales = senales';
if ~isnumeric(senales)
    error('Las señales de entrada deben ser numéricas');
end

if ~isscalar(fs) || fs <= 0
    error('La frecuencia de muestreo debe ser un escalar positivo');
end

% Convertir a matriz si es un vector (una sola señal)
if isvector(senales)
    senales = senales(:);  % Asegurar que sea una columna
end

% Obtener dimensiones
[num_muestras, num_senales] = size(senales);

% Inicializar matriz para señales filtradas
senales_filtradas = zeros(num_muestras, num_senales);

% Aplicar el filtro a cada señal
for i = 1:num_senales
    senal_actual = senales(:, i);
    
    % Seleccionar el método de filtrado
    switch lower(metodo)
        case 'pasabajas'
            senales_filtradas(:, i) = filtro_pasabajas(senal_actual, fs, parametros);
        case 'pasabanda'
            senales_filtradas(:, i) = filtro_pasabanda(senal_actual, fs, parametros);
        case 'media_movil'
            senales_filtradas(:, i) = filtro_media_movil(senal_actual, parametros);
        case 'mediana'
            senales_filtradas(:, i) = filtro_mediana(senal_actual, parametros);
        case 'wavelet'
            senales_filtradas(:, i) = filtro_wavelet(senal_actual, parametros);
        case 'kalman'
            senales_filtradas(:, i) = filtro_kalman(senal_actual, parametros);
        otherwise
            error('Método de filtrado no válido');
    end
end

senales_filtradas = senales_filtradas';
end

function senal_filtrada = filtro_pasabajas(senal, fs, parametros)
% Implementación del filtro pasa bajas

% Obtener la frecuencia de corte
if ~isfield(parametros, 'frecuencia_corte')
    error('Debe especificar la frecuencia de corte para el filtro pasa bajas');
end
frecuencia_corte = parametros.frecuencia_corte;

% Orden del filtro (por defecto 4)
if isfield(parametros, 'orden')
    orden = parametros.orden;
else
    orden = 4;
end

% Frecuencia de Nyquist
nyquist = fs/2;

% Frecuencia normalizada
wn = frecuencia_corte/nyquist;

% Diseñar filtro Butterworth pasa bajas
[b, a] = butter(orden, wn, 'low');

% Aplicar filtro
senal_filtrada = filtfilt(b, a, senal);
end

function senal_filtrada = filtro_pasabanda(senal, fs, parametros)
% Implementación del filtro pasa banda

% Obtener las frecuencias de corte
if ~isfield(parametros, 'frecuencia_baja') || ~isfield(parametros, 'frecuencia_alta')
    error('Debe especificar frecuencia_baja y frecuencia_alta para el filtro pasa banda');
end
frecuencia_baja = parametros.frecuencia_baja;
frecuencia_alta = parametros.frecuencia_alta;

% Orden del filtro (por defecto 4)
if isfield(parametros, 'orden')
    orden = parametros.orden;
else
    orden = 4;
end

% Frecuencia de Nyquist
nyquist = fs/2;

% Frecuencias normalizadas
wn = [frecuencia_baja frecuencia_alta]/nyquist;

% Diseñar filtro Butterworth pasa banda
[b, a] = butter(orden, wn, 'bandpass');

% Aplicar filtro
senal_filtrada = filtfilt(b, a, senal);
end

function senal_filtrada = filtro_media_movil(senal, parametros)
% Implementación del filtro de media móvil

% Obtener el tamaño de la ventana
if ~isfield(parametros, 'ventana')
    error('Debe especificar el tamaño de la ventana para el filtro de media móvil');
end
ventana = parametros.ventana;

% Crear ventana de coeficientes
b = ones(ventana, 1) / ventana;
a = 1;

% Aplicar filtro
senal_filtrada = filtfilt(b, a, senal);
end

function senal_filtrada = filtro_mediana(senal, parametros)
% Implementación del filtro de mediana

% Obtener el tamaño de la ventana
if ~isfield(parametros, 'ventana')
    error('Debe especificar el tamaño de la ventana para el filtro de mediana');
end
ventana = parametros.ventana;

% Aplicar filtro de mediana
senal_filtrada = medfilt1(senal, ventana);
end

function senal_filtrada = filtro_wavelet(senal, parametros)
% Implementación del filtro wavelet

% Obtener la wavelet a usar
if ~isfield(parametros, 'wavelet')
    wavelet = 'db4'; % Por defecto, Daubechies 4
else
    wavelet = parametros.wavelet;
end

% Obtener el nivel de descomposición
if ~isfield(parametros, 'nivel')
    nivel = 4; % Por defecto, nivel 4
else
    nivel = parametros.nivel;
end

% Obtener el umbral
if ~isfield(parametros, 'umbral')
    umbral = 'sqtwolog'; % Por defecto, umbral universal
else
    umbral = parametros.umbral;
end

% Realizar la descomposición wavelet
[C, L] = wavedec(senal, nivel, wavelet);

% Estimar el ruido a partir de los coeficientes de detalle del primer nivel
sigma = median(abs(C(L(1)+1:L(1)+L(2))))/0.6745;

% Aplicar umbral a los coeficientes de detalle
for i = 1:nivel
    % Obtener los coeficientes de detalle
    detalle = detcoef(C, L, i);
    
    % Aplicar umbral
    if ischar(umbral)
        if strcmp(umbral, 'sqtwolog')
            thr = sigma * sqrt(2*log(length(detalle)));
        else
            error('Método de umbral no soportado');
        end
    else
        thr = umbral;
    end
    
    % Aplicar umbral suave
    detalle = wthresh(detalle, 's', thr);
    
    % Actualizar los coeficientes
    C = wsetcoef(C, L, i, detalle);
end

% Reconstruir la señal
senal_filtrada = waverec(C, L, wavelet);
end

function senal_filtrada = filtro_kalman(senal, parametros)
% Implementación del filtro de Kalman

% Obtener parámetros
if ~isfield(parametros, 'Q')
    Q = 1e-5; % Varianza del ruido del proceso
else
    Q = parametros.Q;
end

if ~isfield(parametros, 'R')
    R = 0.1; % Varianza del ruido de medición
else
    R = parametros.R;
end

% Inicializar
x_est = senal(1); % Estimación inicial
p_est = 1; % Covarianza inicial
senal_filtrada = zeros(size(senal));
senal_filtrada(1) = x_est;

% Aplicar filtro de Kalman
for k = 2:length(senal)
    % Predicción
    x_pred = x_est;
    p_pred = p_est + Q;
    
    % Actualización
    K = p_pred / (p_pred + R);
    x_est = x_pred + K * (senal(k) - x_pred);
    p_est = (1 - K) * p_pred;
    
    % Guardar resultado
    senal_filtrada(k) = x_est;
end
end

% Función auxiliar para visualizar resultados del filtrado
function visualizar_filtrado(senales_originales, senales_filtradas, fs, titulo)
% VISUALIZAR_FILTRADO Muestra gráficos comparativos de señales originales y filtradas
%
% Entradas:
%   senales_originales - Matriz donde cada columna es una señal original
%   senales_filtradas - Matriz donde cada columna es una señal filtrada
%   fs - Frecuencia de muestreo en Hz
%   titulo - Título para la figura

% Convertir a matrices si son vectores
if isvector(senales_originales)
    senales_originales = senales_originales(:);
end

if isvector(senales_filtradas)
    senales_filtradas = senales_filtradas(:);
end

% Verificar que ambas matrices tengan el mismo número de filas
if size(senales_originales, 1) ~= size(senales_filtradas, 1)
    error('Las matrices de señales originales y filtradas deben tener el mismo número de filas.');
end

% Obtener dimensiones
[num_muestras, num_senales_orig] = size(senales_originales);
[~, num_senales_filt] = size(senales_filtradas);

% Verificar que ambas matrices tengan el mismo número de columnas
if num_senales_orig ~= num_senales_filt
    error('Las matrices de señales originales y filtradas deben tener el mismo número de columnas.');
end

% Crear vector de tiempo
t = (0:num_muestras-1)' / fs;

% Crear figura
figure;

% Colores para las diferentes señales
colores = {'b', 'g', 'm', 'c', 'y', 'k'};
num_colores = length(colores);

% Gráfico en el dominio del tiempo
subplot(2, 1, 1);
for i = 1:num_senales_orig
    color_idx = mod(i-1, num_colores) + 1;
    
    % Señal original con línea discontinua
    plot(t, senales_originales(:,i), [colores{color_idx}, '--'], 'LineWidth', 1);
    hold on;
    
    % Señal filtrada con línea continua
    plot(t, senales_filtradas(:,i), colores{color_idx}, 'LineWidth', 1.5);
end
grid on;
xlabel('Tiempo (s)');
ylabel('Amplitud');
title([titulo ' - Dominio del tiempo']);

% Crear leyenda dinámica
legend_entries = {};
for i = 1:num_senales_orig
    legend_entries{end+1} = ['Original ' num2str(i)];
    legend_entries{end+1} = ['Filtrada ' num2str(i)];
end
legend(legend_entries);

% Gráfico en el dominio de la frecuencia
subplot(2, 1, 2);

% Preparar arrays para almacenar los espectros
L = num_muestras;
f = fs * (0:(L/2))/L;
P1_orig = zeros(length(f), num_senales_orig);
P1_filt = zeros(length(f), num_senales_filt);

% Calcular FFT para cada señal
for i = 1:num_senales_orig
    % Señal original
    Y_orig = fft(senales_originales(:,i));
    P2_orig = abs(Y_orig/L);
    P1_temp = P2_orig(1:floor(L/2)+1);
    P1_temp(2:end-1) = 2*P1_temp(2:end-1);
    P1_orig(:,i) = P1_temp;
    
    % Señal filtrada
    Y_filt = fft(senales_filtradas(:,i));
    P2_filt = abs(Y_filt/L);
    P1_temp = P2_filt(1:floor(L/2)+1);
    P1_temp(2:end-1) = 2*P1_temp(2:end-1);
    P1_filt(:,i) = P1_temp;
end

% Graficar espectros
for i = 1:num_senales_orig
    color_idx = mod(i-1, num_colores) + 1;
    
    % Espectro original con línea discontinua
    plot(f, P1_orig(:,i), [colores{color_idx}, '--'], 'LineWidth', 1);
    hold on;
    
    % Espectro filtrado con línea continua
    plot(f, P1_filt(:,i), colores{color_idx}, 'LineWidth', 1.5);
end
grid on;
xlabel('Frecuencia (Hz)');
ylabel('|P1(f)|');
title([titulo ' - Espectro de frecuencia']);
legend(legend_entries);

% Ajustar figura
set(gcf, 'Position', [100, 100, 900, 700]);
end

% Ejemplo de uso de los filtros
function ejemplo_filtrado()
% Crear varias señales senoidales con ruido
fs = 1000; % Frecuencia de muestreo en Hz
t = 0:1/fs:1-1/fs; % Vector de tiempo de 1 segundo
t = t(:); % Convertir a columna

% Crear tres señales limpias con diferentes frecuencias
f1 = 50; % Frecuencia fundamental en Hz
f2 = 75; % Frecuencia para segunda señal
f3 = 30; % Frecuencia para tercera señal

% Señales limpias
senal_limpia1 = sin(2*pi*f1*t);
senal_limpia2 = sin(2*pi*f2*t);
senal_limpia3 = sin(2*pi*f3*t);

% Añadir diferentes tipos de ruido
ruido_armonico1 = 0.3 * sin(2*pi*150*t) + 0.2 * sin(2*pi*350*t);
ruido_armonico2 = 0.4 * sin(2*pi*200*t) + 0.1 * sin(2*pi*400*t);
ruido_armonico3 = 0.25 * sin(2*pi*120*t) + 0.3 * sin(2*pi*300*t);

ruido_aleatorio1 = 0.2 * randn(size(t));
ruido_aleatorio2 = 0.3 * randn(size(t));
ruido_aleatorio3 = 0.1 * randn(size(t));

% Crear señales ruidosas
senal_ruidosa1 = senal_limpia1 + ruido_armonico1 + ruido_aleatorio1;
senal_ruidosa2 = senal_limpia2 + ruido_armonico2 + ruido_aleatorio2;
senal_ruidosa3 = senal_limpia3 + ruido_armonico3 + ruido_aleatorio3;

% Combinar las señales en una matriz
senales_limpias = [senal_limpia1, senal_limpia2, senal_limpia3];
senales_ruidosas = [senal_ruidosa1, senal_ruidosa2, senal_ruidosa3];

% Aplicar diferentes filtros a todas las señales a la vez
% 1. Filtro pasa bajas
parametros_pb = struct('frecuencia_corte', 90, 'orden', 4);
senales_filtradas_pb = filtrar_ruido(senales_ruidosas, fs, 'pasabajas', parametros_pb);

% 2. Filtro pasa banda - aplicar diferentes bandas para cada señal
% Para esto necesitamos aplicarlas por separado
parametros_bd1 = struct('frecuencia_baja', 45, 'frecuencia_alta', 55, 'orden', 4);
parametros_bd2 = struct('frecuencia_baja', 70, 'frecuencia_alta', 80, 'orden', 4);
parametros_bd3 = struct('frecuencia_baja', 25, 'frecuencia_alta', 35, 'orden', 4);

senal_filtrada_bd1 = filtrar_ruido(senal_ruidosa1, fs, 'pasabanda', parametros_bd1);
senal_filtrada_bd2 = filtrar_ruido(senal_ruidosa2, fs, 'pasabanda', parametros_bd2);
senal_filtrada_bd3 = filtrar_ruido(senal_ruidosa3, fs, 'pasabanda', parametros_bd3);
senales_filtradas_bd = [senal_filtrada_bd1, senal_filtrada_bd2, senal_filtrada_bd3];

% 3. Filtro wavelet
parametros_wv = struct('wavelet', 'db4', 'nivel', 4, 'umbral', 'sqtwolog');
senales_filtradas_wv = filtrar_ruido(senales_ruidosas, fs, 'wavelet', parametros_wv);

% Visualizar resultados para cada señal
nombres_senales = {'Señal 1 (50 Hz)', 'Señal 2 (75 Hz)', 'Señal 3 (30 Hz)'};
metodos_filtro = {'Pasa Bajas', 'Pasa Banda', 'Wavelet'};

% Visualizar cada señal por separado
for i = 1:3
    figure;
    
    % Señal original vs limpia
    subplot(4, 1, 1);
    plot(t, senales_limpias(:,i), 'k', 'LineWidth', 1.5);
    hold on;
    plot(t, senales_ruidosas(:,i), 'r', 'LineWidth', 0.5);
    grid on;
    title([nombres_senales{i}, ' - Original vs Ruidosa']);
    legend('Limpia', 'Ruidosa');
    
    % Filtro pasa bajas
    subplot(4, 1, 2);
    plot(t, senales_ruidosas(:,i), 'r', 'LineWidth', 0.5);
    hold on;
    plot(t, senales_filtradas_pb(:,i), 'b', 'LineWidth', 1.5);
    grid on;
    title(['Filtro ', metodos_filtro{1}]);
    legend('Ruidosa', 'Filtrada');
    
    % Filtro pasa banda
    subplot(4, 1, 3);
    plot(t, senales_ruidosas(:,i), 'r', 'LineWidth', 0.5);
    hold on;
    plot(t, senales_filtradas_bd(:,i), 'g', 'LineWidth', 1.5);
    grid on;
    title(['Filtro ', metodos_filtro{2}]);
    legend('Ruidosa', 'Filtrada');
    
    % Filtro wavelet
    subplot(4, 1, 4);
    plot(t, senales_ruidosas(:,i), 'r', 'LineWidth', 0.5);
    hold on;
    plot(t, senales_filtradas_wv(:,i), 'm', 'LineWidth', 1.5);
    grid on;
    title(['Filtro ', metodos_filtro{3}]);
    legend('Ruidosa', 'Filtrada');
    
    % Ajustar figura
    set(gcf, 'Position', [100 + (i-1)*300, 100, 600, 800]);
    sgtitle([nombres_senales{i}, ' - Comparación de Filtros']);
end

% Comparación de los tres métodos en una sola figura
figure;
for i = 1:3
    subplot(3, 1, i);
    plot(t, senales_limpias(:,i), 'k', 'LineWidth', 2);
    hold on;
    plot(t, senales_filtradas_pb(:,i), 'r', 'LineWidth', 1);
    plot(t, senales_filtradas_bd(:,i), 'g', 'LineWidth', 1);
    plot(t, senales_filtradas_wv(:,i), 'b', 'LineWidth', 1);
    grid on;
    xlabel('Tiempo (s)');
    ylabel('Amplitud');
    title(nombres_senales{i});
    if i == 1
        legend('Señal Limpia', 'Pasa Bajas', 'Pasa Banda', 'Wavelet');
    end
end
sgtitle('Comparación de métodos de filtrado para las tres señales');
set(gcf, 'Position', [100, 100, 800, 600]);

% Ejemplo de cómo aplicar un mismo filtro a las tres señales simultáneamente
% y visualizar los resultados en frecuencia
figure;
% Calcular espectros
[P_orig, f] = calcular_espectro(senales_ruidosas, fs);
[P_filt, ~] = calcular_espectro(senales_filtradas_pb, fs);

% Visualizar espectros
for i = 1:3
    subplot(3, 1, i);
    plot(f, P_orig(:,i), 'r');
    hold on;
    plot(f, P_filt(:,i), 'b');
    grid on;
    xlabel('Frecuencia (Hz)');
    ylabel('Magnitud');
    title(['Espectro de Frecuencia - ', nombres_senales{i}]);
    if i == 1
        legend('Original', 'Filtrada');
    end
    xlim([0, 500]);
end
sgtitle('Espectros de frecuencia antes y después del filtrado pasa bajas');
set(gcf, 'Position', [400, 100, 800, 600]);
end

% Función auxiliar para calcular espectros
function [P1, f] = calcular_espectro(senales, fs)
    [L, num_senales] = size(senales);
    f = fs * (0:(L/2))/L;
    P1 = zeros(length(f), num_senales);
    
    for i = 1:num_senales
        Y = fft(senales(:,i));
        P2 = abs(Y/L);
        P1_temp = P2(1:floor(L/2)+1);
        P1_temp(2:end-1) = 2*P1_temp(2:end-1);
        P1(:,i) = P1_temp;
    end
end