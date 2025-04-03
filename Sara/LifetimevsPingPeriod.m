clc;
clear;
close all;

%% ---------------------------
% Parameters from the paper
%% ---------------------------

V = 3.3;                 
battery_mAh = 3000;      
battery_J = battery_mAh / 1000 * V * 3600;  

BW = 125e3;             
SF = 9;                 
M = 1;                  
D = 100;                
F = 8;                   

beacon_period   = 128;  
beacon_duration = 2.12;  

% Currents in different modes (from LoRa datasheet)
Ir = 11e-3;             
It = 29e-3;             
Is = 0.2e-6;            


% Ping period range (2s to 64s)


ping_period_values = [2, 4, 8, 16, 32, 64]; 
ping_duration = 0.03; 

lifetime_LPWC = zeros(size(ping_period_values));
lifetime_LoRa = zeros(size(ping_period_values));


% Loop over Ping Periods


for i = 1:length(ping_period_values)
    
    ping_period = ping_period_values(i);
    
    Ts = 2^SF / BW;
    L = L_value(SF, BW);

    % LPWC Energy
    T_opt = sqrt( (35/11) * Ts * (D / M) );
    Ec = (V / 1000) * (17.5 * Ts * (D / T_opt) - 17.5 * Ts * M);
    Er = (V / 1000) * (5.5 * M * T_opt + 11 * M * L);
    Et = (V / 1000) * (29 * M * F * Ts + 29 * M * L);

    E_LPWC = Ec + Er + Et;

    % LoRaWAN Energy
    n_beacon = D / beacon_period;
    n_ping   = D / ping_period;

    E_b = V * Ir * beacon_duration * n_beacon;
    E_p = V * Ir * ping_duration  * n_ping;
    E_r = V * Ir * L;
    E_t = V * It * L;

    active_time = n_beacon * beacon_duration + n_ping * ping_duration + 2 * L;
    sleep_time = T_opt - active_time;
    Es = V * Is * sleep_time;

    E_LoRa = Es + E_r + E_t + E_p + E_b;

    % Lifetime (days)
    lifetime_LPWC(i) = (battery_J / E_LPWC) * (D / 86400);
    lifetime_LoRa(i) = (battery_J / E_LoRa) * (D / 86400);

end

figure;
plot(ping_period_values, lifetime_LoRa, '-o', 'LineWidth', 2);
hold on;
plot(ping_period_values, lifetime_LPWC, '-o', 'LineWidth', 2);
legend('LoRaWAN', 'LPWC');
xlabel('Ping Periodicity (s)');
ylabel('Lifetime (day)');
title('Lifetime vs Ping Period');
grid on;


% --- Helper Function ---
function L = L_value(SF, BW)
    payload_bytes = 30;
    payload_bits = payload_bytes * 8;
    Ts = 2^SF / BW;
    L = payload_bits / (SF * (4/5)) * Ts;
end
