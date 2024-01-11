%% Generating Power Quality Disturbance Dataset using pqmodel

% This MATLAB script is designed to generate a comprehensive dataset of power 
% quality disturbances using the 'pqmodel' function. It systematically creates 
% a wide array of power quality signals, encompassing various disturbances 
% like voltage sags, swells, harmonics, transients, and interruptions.

numSignals = 50;
sampligFrequency = 10000;

f = 50; % Singal frequency
n = 5; % Number of cycles per sample
A = 400; % Signal Amplitud
unbalance = 3; % percentage of unbalance

dataset = pqmodel(numSignals, sampligFrequency, f, n, A, unbalance, true);

name = sprintf('DatasetThreePSignal_Noise.mat');
save(name, "dataset");



