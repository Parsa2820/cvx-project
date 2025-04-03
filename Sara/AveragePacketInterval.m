clc;
clear;
close all;

%% ---------------------------
% Fixed Parameters
%% ---------------------------

V = 3.3;                
battery_mAh = 3000;     
battery_J = battery_mAh / 1000 * V * 3600;

BW = 125e3;             % Fixed Bandwidth
M = 1;                  
F = 8;                  
SF = 9;                 % Fixed Spreading Factor

beacon_period   = 128;  
beacon_duration = 2.12; 
ping_period     = 8;    
ping_duration   = 0.03; 

Ir = 11e-3;             % Receive
It = 29e-3;             % Transmit
Is = 0.2e-6;            % Sleep

%% ---------------------------
% D values to simulate
%% ---------------------------

D_values = [50, 100, 150, 200, 250, 300]; % Average packet interval
lifetime_LPWC = zeros(size(D_values));
lifetime_LoRa = zeros(size(D_values));

%% ---------------------------
% Loop over D values
%% ---------------------------

for i = 1:length(D_values)

    D = D_values(i); % Update interval
    BW_used = BW;
    Ts = 2^SF / BW_used;
    L = L_value(SF, BW_used);
    
    % T_opt
    T_opt = sqrt((35/11) * (2^SF / BW_used) * (D / M));
    
    % LPWC Energies
    Ec = (V / 1000) * (17.5 * Ts * (D / T_opt) - 17.5 * Ts * M);
    Er = (V / 1000) * (5.5 * M * T_opt + 11 * M * L);
    Et = (V / 1000) * (29 * M * F * Ts + 29 * M * L);
    
    E_LPWC = Ec + Er + Et;
    
    % LoRaWAN Energies
    n_beacon = D / beacon_period;
    n_ping   = D / ping_period;
    
    E_b = V * Ir * beacon_duration * n_beacon;
    E_p = V * Ir * ping_duration  * n_ping;
    E_r = V * Ir * L;
    E_t = V * It * L;
    
    active_time = n_beacon * beacon_duration + n_ping * ping_duration + 2*L;
    sleep_time = T_opt - active_time;
    Es = V * Is * sleep_time;
    
    E_LoRa = Es + E_r + E_t + E_p + E_b;

    % Lifetime in days
    lifetime_LPWC(i) = (battery_J / E_LPWC) * (D / 86400);
    lifetime_LoRa(i) = (battery_J / E_LoRa) * (D / 86400);
    
end

%% ---------------------------
% Plotting
%% ---------------------------

figure;
plot(D_values, lifetime_LoRa, '-o', 'LineWidth', 2);
hold on;
plot(D_values, lifetime_LPWC, '-o', 'LineWidth', 2);
legend('LoRaWAN', 'LPWC');
xlabel('Average packet interval (s)');
ylabel('Lifetime (day)');
title('Lifetime vs Average Packet Interval');
grid on;

% Helper Function
function L = L_value(SF, BW)
    payload_bytes = 30;
    payload_bits = payload_bytes * 8;
    Ts = 2^SF / BW;
    L = payload_bits / (SF * (4/5)) * Ts;
end