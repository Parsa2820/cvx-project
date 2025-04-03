clc;
clear;
close all;

% ----------------------------
% Parameters
% ----------------------------
BW = 125e3;                  % Bandwidth fixed
M = 1;
D = 100;
V = 3.3;
F = 8;
ping_period = 8;
beacon_period = 128;
payload_bytes = 30;

% SF range
SF_values = 7:12;
latency_LPWC = zeros(size(SF_values));
latency_LoRaWAN = zeros(size(SF_values));

% ----------------------------
% Loop over SF
% ----------------------------
for i = 1:length(SF_values)
    
    SF = SF_values(i);
    
    Ts = 2^SF / BW;  % Symbol duration
    payload_bits = payload_bytes * 8;
    L = payload_bits / (SF * (4/5)) * Ts;  % Payload airtime
    
    % LPWC Latency = Optimal Cycle Period
    T_opt = sqrt( (35/11) * (2^SF / BW) * (D / M) );
    latency_LPWC(i) = T_opt;
    
    % LoRaWAN latency = half of ping period + airtime
    latency_LoRaWAN(i) = 4; % constant during this simulation

end

% ----------------------------
% Plotting
% ----------------------------
figure;
plot(SF_values, latency_LoRaWAN, '-','LineWidth', 2);
hold on;
plot(SF_values, latency_LPWC, '-','LineWidth', 2);
legend('LoRaWAN','LPWC');
ylim([0.3,4.3])
xlabel('SF');
ylabel('Packet latency (s)');
title('Packet Latency vs SF');
grid on;
