clc;
clear;
close all;

%% ---------------------------
% Parameters from the paper
%% ---------------------------

V = 3.3;                 
battery_mAh = 3000;      
battery_J = battery_mAh / 1000 * V * 3600;  

SF = 9;  % Fixed Spreading Factor
M = 1;   
D = 100;                
F = 8;                   
beacon_period   = 128;   
beacon_duration = 2.12;  
ping_period     = 8;     
ping_duration   = 0.03;  

% Currents in different modes
Ir = 11e-3;             
It = 29e-3;             
Is = 0.2e-6;            

%% ---------------------------
% BW values to simulate
%% ---------------------------

BW_values = [62.5e3, 125e3, 250e3, 500e3];  
lifetime_daysLPWC = zeros(size(BW_values));
lifetime_daysLoRaWAN = zeros(size(BW_values));

%% ---------------------------
% Loop over BW
%% ---------------------------

for i = 1:length(BW_values)
    
    BW = BW_values(i);
    Ts = 2^SF / BW;
    L = L_value(SF, BW);

    T_opt = sqrt( (35/11) * (2^SF / BW) * (D / M) );

    Ec = (3.3 / 1000) * (17.5 * (2^SF / BW) * (D / T_opt) - 17.5 * (2^SF / BW) * M);
    Er = (3.3 / 1000) * (5.5 * M * T_opt + 11 * M * L);   
    Et = (3.3 / 1000) * (29 * M * F * Ts + 29 * M * L);

    n_beacon = D / beacon_period;
    n_ping   = D / ping_period;

    E_b = V * Ir * beacon_duration * n_beacon;
    E_p = V * Ir * ping_duration  * n_ping;
    E_r = V * Ir * L;
    E_t = V * It * L;

    active_time = n_beacon * beacon_duration + n_ping * ping_duration + L + L;
    sleep_time = T_opt - active_time;
    Es = V * Is * sleep_time;

    E_LPWC = Ec + Er + Et;
    E_LoRaWAN = Es + E_r + E_t + E_p + E_b;

    lifetime_daysLPWC(i) = (battery_J / E_LPWC) * (D / 86400);
    lifetime_daysLoRaWAN(i) = (battery_J / E_LoRaWAN) * (D / 86400);

end


figure;
plot(BW_values, lifetime_daysLoRaWAN, '-o', 'LineWidth', 2);
hold on
plot(BW_values, lifetime_daysLPWC, '-o', 'LineWidth', 2);
legend('LoRaWAN', 'LPWC');
xlabel('BW');
ylabel('Lifetime (day)');
title('Lifetime vs Bandwidth');
grid on;
set(gca, 'XTick', BW_values, 'XTickLabel', {'62.5k','125k','250k','500k'});

%% ---------------------------
% Helper function
function L = L_value(SF, BW)
    payload_bytes = 30;
    payload_bits = payload_bytes * 8;
    Ts = 2^SF / BW;              
    L = payload_bits / (SF * (4/5)) * Ts;   
end
