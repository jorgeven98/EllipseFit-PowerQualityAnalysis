%% MATLAB Script for Generating Power Quality Disturbance Dataset using pqmodel

% This MATLAB script is designed to generate a comprehensive dataset of power 
% quality disturbances using the 'pqmodel' function. It systematically creates 
% a wide array of power quality signals, encompassing various disturbances 
% like voltage sags, swells, harmonics, transients, and interruptions.

numPhases = 3;
numSignals = 30;
SignalLenght = 10000;
numTypes = 29;

f = 50;
n = 5;
A = 400;
thetha = [0, 4*pi/3, 2*pi/3];
des = [1,1,1];

for i=0:2
    
    if i ~= 0
        des = [0.97+(1.03-0.97)*rand, 0.97+(1.03-0.97)*rand, 0.97+(1.03-0.97)*rand];
    end

    v1 = pqmodel(numSignals, SignalLenght, f, n, A, thetha(1)*des(1));
    v2 = pqmodel(numSignals, SignalLenght, f, n, A, thetha(2)*des(2));
    v3 = pqmodel(numSignals, SignalLenght, f, n, A, thetha(3)*des(3));
    
    dataset = {v1, v2, v3};
    name = sprintf('DatasetThreePSignal%d.mat', i);
    save(name, "dataset");
end

