%% Generating Power Quality Disturbance Dataset using pqmodel

% This MATLAB script is designed to generate a comprehensive dataset of power 
% quality disturbances using the 'pqmodel' function. It systematically creates 
% a wide array of power quality signals, encompassing various disturbances 
% like voltage sags, swells, harmonics, transients, and interruptions.

numPhases = 3;
numSignals = 30;
SignalLenght = 10000;

f = 50;
n = 5;
A = 400;
ang_offset_per = 3;

dataset = pqmodel(numSignals, SignalLenght, f, n, A, ang_offset_per);

name = sprintf('DatasetThreePSignal_10types.mat');
save(name, "dataset");



