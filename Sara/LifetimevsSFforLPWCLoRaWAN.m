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
beacon_period   = 128;   % Beacon periodicity in seconds
beacon_duration = 2.12;  % Receiving duration for beacon in seconds
ping_period     = 8;     % Ping periodicity in seconds
ping_duration   = 0.03;  % Ping duration in seconds

% Currents in different modes (from LoRa datasheet)

Ir = 11e-3;             % Receive
It = 29e-3;             % Transmit
Is = 0.2e-6;            % Sleep

% SF values to simulate

SF_values = 7:12;        % Spreading Factors
lifetime_daysLPWC = zeros(size(SF_values));
lifetime_daysLoRaWAN= zeros(size(SF_values));
% Compute Lifetime for Each SF
for i = 1:length(SF_values)
    
    SF = SF_values(i);
    Ts = 2^SF / BW;
    L = L_value(SF, BW);

    
    % Step 1 - Compute Optimal T_opt (Eq. 17)
    T_opt = sqrt( (35/11) * (2^SF / BW) * (D / M) );

    % Step 2 - Compute Ec, Er, Et (Eq. 16)
    Ec = (3.3 / 1000) * (17.5 * (2^SF / BW) * (D / T_opt) - 17.5 * (2^SF / BW) * M);
    Er = (3.3 / 1000) * (5.5 * M * T_opt + 11 * M * L);   % Payload duration handled below
    Et = (3.3 / 1000) * (29 * M * F * (2^SF / BW) + 29 * M * L);

    n_beacon = D / beacon_period;
    n_ping   = D / ping_period;

    E_b = V * Ir * beacon_duration * n_beacon;
    E_p = V * Ir * ping_duration  * n_ping;
    E_r = V * Ir * L;
    E_t = V * It * L;

 
    % Sleep time for LoRaWAN node
    active_time = n_beacon * beacon_duration + n_ping * ping_duration + L + L;
    sleep_time = T_opt - active_time;
    Es = V * Is * sleep_time;


    E_LPWC = Ec + Er + Et;
    E_LoRaWAN = Es + E_r + E_t + E_p + E_b;

    % Step 3 - Lifetime (days)
    lifetime_daysLPWC(i) = (battery_J / E_LPWC) * (D / 86400); % Convert to days
    lifetime_daysLoRaWAN(i) = (battery_J / E_LoRaWAN) * (D / 86400); % Convert to days


end


plot(SF_values, lifetime_daysLPWC, '-o', 'LineWidth', 2);
hold on
plot(SF_values, lifetime_daysLoRaWAN, '--', 'LineWidth', 2)
legend('LPWC','LoRaWAN')
xlabel('Spreading Factor (SF)', 'FontSize', 12);
ylabel('Lifetime (days)', 'FontSize', 12);
title('Lifetime vs SF');
grid on;


% --- Helper Function ---
function L = L_value(SF, BW)
    % Approximation of Payload Duration (in seconds)
    payload_bytes = 30;
    payload_bits = payload_bytes * 8;
    Ts = 2^SF / BW;              % Symbol duration
    L = payload_bits / (SF * (4/5)) * Ts;   % Payload airtime
end