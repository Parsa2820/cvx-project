clc;
clear;
close all;

%  Step 1: Define Simulation Parameters

voltage = 3.3;                      % Device voltage (Volts)
bandwidth = 125e3;                  % Bandwidth (Hz)
spreadingFactor = 9;               % SF = 9
codingRate = 4/5;                   % Coding Rate
payloadSize_bytes = 30;            % Payload size in bytes
averageInterval = 100;             % Average packet interval (seconds)
batteryCapacity_mAh = 3000;        % Battery capacity
batteryEnergy_Joules = batteryCapacity_mAh / 1000 * voltage * 3600;

% Currents in different modes (from LoRa datasheet)
current_CAD = 8.75e-3;   % CAD mode current (Amps)
current_RX  = 11.5e-3;   % Receive mode current (Amps)
current_TX  = 28e-3;     % Transmit mode current (Amps)

% Step 2: Define Cycle Periods (T) and Corresponding Preamble Lengths

cyclePeriods = [0.3, 0.4, 0.45, 0.5, 0.6];          % In seconds
preambleSymbols = [69, 94, 106, 118, 143];          % Number of preamble symbols


% Step 3: Calculate Constants

symbolDuration = 2^spreadingFactor / bandwidth;    % Duration of one LoRa symbol (seconds)

% Estimate payload duration (simplified)
payloadBits = payloadSize_bytes * 8;
payloadDuration = payloadBits * symbolDuration / (spreadingFactor * codingRate); % Approximate

% Assume 1 message per D = 100s
numMessages = 1;
duration_D = numMessages * averageInterval;


% Step 4: Compute Lifetime for Each Cycle Period
lifetimes_in_days = zeros(size(cyclePeriods));

for i = 1:length(cyclePeriods)
    
    T = cyclePeriods(i);                    % Current cycle period
    preambleLength = preambleSymbols(i);    % Number of preamble symbols for current T
    preambleDuration = preambleLength * symbolDuration;

    % Number of CAD cycles in time D
    numCADcycles = duration_D / T;

    % Time spent in each mode
    totalCADtime = 2 * (numCADcycles - numMessages) * symbolDuration;
    totalRXtime  = numMessages * (preambleDuration + payloadDuration / 2);
    totalTXtime  = numMessages * (preambleDuration + payloadDuration);

    % Energy spent in each mode
    energy_CAD = voltage * current_CAD * totalCADtime;
    energy_RX  = voltage * current_RX * totalRXtime;
    energy_TX  = voltage * current_TX * totalTXtime;

    totalEnergy = energy_CAD + energy_RX + energy_TX;

    % Convert total energy usage to lifetime in days
    lifetimes_in_days(i) = (batteryEnergy_Joules / totalEnergy) * (duration_D / 86400);
end

plot(cyclePeriods, lifetimes_in_days, '-o', 'LineWidth', 2);
xlabel('Cycle Period T (s)', 'FontSize', 12);
ylabel('Node Lifetime (days)', 'FontSize', 12);
title(' Node Lifetime vs. Cycle Period — Verifying Optimal T', 'FontSize', 13);
grid on;
