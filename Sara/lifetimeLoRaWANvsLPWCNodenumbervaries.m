clc;
clear;
close all;



V = 3.3;                 % Voltage (V)
battery_mAh = 3000;      % Battery capacity in mAh
battery_J = battery_mAh / 1000 * V * 3600;  % Convert to Joules

BW = 125e3;              % Bandwidth (Hz)
M = 1;                   % Number of transmitted packets (M=1 assumed)
D = 100;                 % Average interval duration (s)
F = 8;                   % Short preamble length (fixed)
beacon_period   = 128;   % Beacon periodicity (s)
beacon_duration = 2.12;  % Beacon receive duration (s)
ping_period     = 8;     % Ping periodicity (s)
ping_duration   = 0.03;  % Ping duration (s)

% Currents
Ir = 11e-3;              % Receive
It = 29e-3;              % Transmit
Is = 0.2e-6;             % Sleep



SF_set = [7, 9, 11];
node_num = 1:6;

lifetime_LoRaWAN = zeros(length(SF_set), length(node_num));
lifetime_LPWC    = zeros(length(SF_set), length(node_num));



for k = 1:length(SF_set)
    SF = SF_set(k);
    for n = 1:length(node_num)
        N = node_num(n);

        Ts = 2^SF / BW;
        L = L_value(SF, BW);

        % --- LPWC ---
        T_opt = sqrt( (35/11) * (2^SF / BW) * (D / M) );

        Ec = (3.3 / 1000) * (17.5 * (2^SF / BW) * (D / T_opt) - 17.5 * (2^SF / BW) * N);
        Er = (3.3 / 1000) * (5.5 * N * T_opt + 11 * N * L);
        Et = (3.3 / 1000) * (29 * N * F * (2^SF / BW) + 29 * N * L);

        E_LPWC = Ec + Er + Et;

        % --- LoRaWAN ---
        n_beacon = D / beacon_period;
        n_ping   = D / ping_period;

        E_b = V * Ir * beacon_duration * n_beacon;
        E_p = V * Ir * ping_duration  * n_ping;
        E_r = V * Ir * L * N;
        E_t = V * It * L * N;

        active_time = n_beacon * beacon_duration + n_ping * ping_duration + L * N + L * N;
        sleep_time = D - active_time;
        Es = V * Is * sleep_time;

        E_LoRaWAN = Es + E_r + E_t + E_p + E_b;

        % --- Lifetime ---
        lifetime_LPWC(k, n)    = (battery_J / E_LPWC) * (D / 86400);
        lifetime_LoRaWAN(k, n) = (battery_J / E_LoRaWAN) * (D / 86400);
    end
end



figure;
hold on;

% LoRaWAN
plot(node_num, lifetime_LoRaWAN(1,:), '-o', 'LineWidth', 1.5);
plot(node_num, lifetime_LoRaWAN(2,:), '-^', 'LineWidth', 1.5);
plot(node_num, lifetime_LoRaWAN(3,:), '-x', 'LineWidth', 1.5);

% LPWC
plot(node_num, lifetime_LPWC(1,:), '--o', 'LineWidth', 1.5);
plot(node_num, lifetime_LPWC(2,:), '--^', 'LineWidth', 1.5);
plot(node_num, lifetime_LPWC(3,:), '--x', 'LineWidth', 1.5);

legend('SF7, LoRaWAN', 'SF9, LoRaWAN', 'SF11, LoRaWAN', ...
       'SF7, LPWC', 'SF9, LPWC', 'SF11, LPWC', 'Location', 'northeast');

xlabel('Node number', 'FontSize', 12);
ylabel('Lifetime (day)', 'FontSize', 12);
title('Comparison of lifetime vs Node Number', 'FontSize', 12);
grid on;



function L = L_value(SF, BW)
    payload_bytes = 30;
    payload_bits = payload_bytes * 8;
    Ts = 2^SF / BW;              
    L = payload_bits / (SF * (4/5)) * Ts;   
end
