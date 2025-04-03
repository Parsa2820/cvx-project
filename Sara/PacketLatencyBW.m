clc;
clear;
close all;

%% Parameters

SF = 9; % Fixed SF as in the paper
D = 100; % Average interval duration
ping_period = 8; % ping periodicity
F = 8;   % Short preamble length (fixed)

%% Bandwidth values
BW_values = [62.5e3, 125e3, 250e3, 500e3];  

%% Initialize arrays
latency_LPWC = zeros(size(BW_values));
latency_LoRaWAN = zeros(size(BW_values));

%% Compute latency
for i = 1:length(BW_values)
    
    BW = BW_values(i);
    Ts = 2^SF / BW; % Symbol duration
    
    % Payload duration (airtime)
    L = L_value(SF, BW);
    
    % Optimal T_opt from Eq. (17)
    T_opt = sqrt( (35/11) * (2^SF / BW) * (D) );
    
    %Latencies
    latency_LoRaWAN(i) = ping_period / 2; % Always 4 seconds
    
    % LPWC latency (Eq. 20)
    latency_LPWC(i) = (5.5 * T_opt + 11 * L + 29 * F * Ts + 29 * L) / 16;
    
end


figure;
plot(BW_values, latency_LoRaWAN, '-o', 'LineWidth', 2);
hold on;
plot(BW_values, latency_LPWC, '-o', 'LineWidth', 2);
legend('LoRaWAN', 'LPWC', 'Location', 'northwest');
xlabel('BW');
ylabel('Packet latency (s)');
ylim([0.3,4.3])
title('Packet Latency vs Bandwidth');
grid on;
set(gca, 'XTick', BW_values, 'XTickLabel', {'62.5k','125k','250k','500k'});

% Helper Function
function L = L_value(SF, BW)
    payload_bytes = 30;
    payload_bits = payload_bytes * 8;
    Ts = 2^SF / BW;
    L = payload_bits / (SF * (4/5)) * Ts;
end
