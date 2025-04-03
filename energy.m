%% energy_LPWC.m
% This script plots the energy consumption model from Section 3.3 of
% Hong et al. (2023) for the LPWC protocol.
%
% The energy consumption model is:
%   E_lpwc(T) = 2 * V * I_c * (2^SF/BW) * ((D/T) - M) + V * I_r * M * ((T/2) + L) + V * I_t * M * (T + L)
%
% where:
%   T  : Cycle period (s)
%   D  : Whole duration (average packet interval) (s)
%   M  : Number of packets in duration D
%   L  : Payload time (s)
%   V  : Chip voltage (V)
%   I_c: CAD current (A)
%   I_r: Reception current (A)
%   I_t: Transmission current (A)
%   BW : Bandwidth (Hz)
%   SF : Spreading factor
%
% Author: Your Name
% Date: Today's Date

%% Define system parameters (example values based on the paper)
V    = 3.3;            % Voltage (V)
I_c  = 8.75e-3;        % CAD current (A) [8.75 mA]
I_r  = 11e-3;          % Reception current (A) [11 mA]
I_t  = 29e-3;          % Transmission current (A) [29 mA]
BW   = 125e3;          % Bandwidth (Hz) (125 kHz)
SF   = 9;              % Spreading factor (e.g., 9)
D    = 100;            % Whole duration (s) (e.g., average packet interval 100 s)
M    = 1;              % Number of packets generated in duration D (assume one packet per interval)
L    = 0.5;            % Payload time (s) (assumed)

%% Define a range for the cycle period T (in seconds)
T_vals = linspace(0.3, 0.6, 1000);  % Explore T from 0.3 s to 0.6 s

%% Compute the energy consumption for each T using the model from Eq. (12)
E_lpwc = 2 * V * I_c * (2^SF / BW) .* ((D ./ T_vals) - M) + ...
         V * I_r * M .* ((T_vals / 2) + L) + ...
         V * I_t * M .* (T_vals + L);

%% Calculate the analytical optimal cycle period T_opt (from Eq. (14))
T_opt = sqrt((4 * I_c / (I_r + 2 * I_t)) * (2^SF / BW) * (D / M));

%% Evaluate the energy at T_opt
E_opt = 2 * V * I_c * (2^SF / BW) * ((D / T_opt) - M) + ...
        V * I_r * M * ((T_opt / 2) + L) + ...
        V * I_t * M * (T_opt + L);

%% Plot the energy consumption vs. cycle period T
figure;
plot(T_vals, E_lpwc, 'b-', 'LineWidth', 2);
hold on;
plot(T_opt, E_opt, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');  % Mark the optimal point
xlabel('Cycle Period T (s)');
ylabel('Energy Consumption E_{lpwc} (J)');
title('LPWC Energy Model (Section 3.3 of Hong et al. 2023)');
grid on;
legend('Energy Consumption', 'Optimal T', 'Location', 'Best');