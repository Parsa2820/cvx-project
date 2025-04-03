%% MATLAB Code for Section II-E Optimization Problems with Plots (Corrected Division)
% This code uses CVX (http://cvxr.com/cvx/) to solve:
%
% 1) Delay Constrained Problem:
%    minimize    E_multi-hop
%    subject to  Delay <= V_threshold
%
% 2) Energy Constrained Problem:
%    minimize    Delay
%    subject to  E_multi-hop <= E_threshold
%
% where:
%   E_single = 2*V*Ic*(2^SF/BW)*(D*inv_pos(T) - M) + V*Ir*M*(T/2 + L) + V*It*M*(T + L)
%   E_multi-hop = (2*log2(N) - 1) * E_single
%   Delay = (log2(N)-0.5)*T
%
% After solving the problems, the code plots:
%   - For the delay constrained problem: Energy vs. T and Delay vs. T.
%   - For the energy constrained problem: a dual-axis plot showing both Delay and Energy vs. T.
%
% Adjust parameter values as needed.

%% Define Parameters
V   = 3.3;        % Supply voltage (Volts)
Ic  = 0.015;      % Current in CAD mode (Amperes)
Ir  = 0.010;      % Current in Reception mode (Amperes)
It  = 0.020;      % Current in Transmission mode (Amperes)
SF  = 7;          % Spreading factor
BW  = 125e3;      % Bandwidth (Hz)
D   = 3600;       % Total duration (seconds)
M   = 10;         % Number of packets per cycle
L   = 0.05;       % Payload transmission time (seconds)
N   = 16;         % Number of nodes in the network

% Thresholds (set according to application requirements)
V_threshold = 10; % Delay threshold (seconds)
E_threshold = 50; % Energy threshold (Joules)

% Derived parameters
k = log2(N);
Q_factor     = 2*k - 1;       % Expected number of hops: E[Q] ≈ 2*log2(N)-1
Delay_factor = k - 0.5;       % Delay = (log2(N)-0.5)*T

%% 1) Delay Constrained Optimization: Minimize Energy Consumption
cvx_begin quiet
    variable T_delay  % Cycle period T (decision variable)
    expressions E_single Delay E_multi

    % Energy consumption for a single wake-up cycle:
    % Replace D/T_delay with D*inv_pos(T_delay) for CVX compatibility.
    E_single = 2*V*Ic*(2^SF/BW)*(D*inv_pos(T_delay) - M) + ...
               V*Ir*M*(T_delay/2 + L) + ...
               V*It*M*(T_delay + L);
    % Multi-hop energy consumption (sum over hops)
    E_multi = Q_factor * E_single;
    % Total delay in the multi-hop network
    Delay = Delay_factor * T_delay;

    minimize( E_multi )
    subject to
        Delay <= V_threshold;
        T_delay > 0;
cvx_end

fprintf('Delay Constrained Optimization:\n');
fprintf('Optimal cycle period T = %.4f seconds\n', T_delay);
fprintf('Minimum multi-hop energy consumption = %.4f Joules\n', E_multi);
fprintf('Corresponding delay = %.4f seconds\n\n', Delay);

%% 2) Energy Constrained Optimization: Minimize Delay
cvx_begin quiet
    variable T_energy  % Cycle period T (decision variable)
    expressions E_single2 Delay2 E_multi2

    % Replace D/T_energy with D*inv_pos(T_energy)
    E_single2 = 2*V*Ic*(2^SF/BW)*(D*inv_pos(T_energy) - M) + ...
                V*Ir*M*(T_energy/2 + L) + ...
                V*It*M*(T_energy + L);
    E_multi2 = Q_factor * E_single2;
    Delay2   = Delay_factor * T_energy;

    minimize( Delay2 )
    subject to
        E_multi2 <= E_threshold;
        T_energy > 0;
cvx_end

fprintf('Energy Constrained Optimization:\n');
fprintf('Optimal cycle period T = %.4f seconds\n', T_energy);
fprintf('Multi-hop energy consumption = %.4f Joules\n', E_multi2);
fprintf('Minimum delay = %.4f seconds\n\n', Delay2);

%% Plotting Results for Delay Constrained Optimization
% For the delay constrained problem the feasible region is defined by:
% Delay = (log2(N)-0.5)*T <= V_threshold  =>  T <= V_threshold/Delay_factor
T_max_delay = V_threshold / Delay_factor;
T_range_delay = linspace(0.1, T_max_delay*1.5, 500);

% Compute energy and delay over the range
E_single_delay = 2*V*Ic*(2^SF/BW).*(D./T_range_delay - M) + ...
                 V*Ir*M*(T_range_delay/2 + L) + ...
                 V*It*M*(T_range_delay + L);
E_multi_delay = Q_factor .* E_single_delay;
Delay_vals    = Delay_factor .* T_range_delay;

figure;
subplot(2,1,1);
plot(T_range_delay, E_multi_delay, 'b-', 'LineWidth', 2);
hold on;
plot(T_delay, E_multi, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
xline(T_max_delay, 'k--', 'LineWidth', 1.5);
xlabel('Cycle Period T (seconds)');
ylabel('Multi-hop Energy (Joules)');
title('Delay Constrained Optimization: Energy vs T');
legend('E_{multi-hop}(T)', 'Optimal T', 'Max T for Delay Constraint','Location','best');
grid on;

subplot(2,1,2);
plot(T_range_delay, Delay_vals, 'm-', 'LineWidth', 2);
hold on;
plot(T_delay, Delay, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
yline(V_threshold, 'k--', 'LineWidth', 1.5);
xlabel('Cycle Period T (seconds)');
ylabel('Delay (seconds)');
title('Delay Constrained Optimization: Delay vs T');
legend('Delay(T)', 'Optimal T', 'Delay Threshold','Location','best');
grid on;

%% Plotting Results for Energy Constrained Optimization
% For the energy constrained problem we plot both Delay and Energy versus T.
T_range_energy = linspace(0.1, 10, 500);
E_single_energy = 2*V*Ic*(2^SF/BW).*(D./T_range_energy - M) + ...
                  V*Ir*M*(T_range_energy/2 + L) + ...
                  V*It*M*(T_range_energy + L);
E_multi_energy = Q_factor .* E_single_energy;
Delay_energy   = Delay_factor .* T_range_energy;

figure;
yyaxis left
plot(T_range_energy, Delay_energy, 'm-', 'LineWidth', 2);
ylabel('Delay (seconds)');
hold on;
yyaxis right
plot(T_range_energy, E_multi_energy, 'b-', 'LineWidth', 2);
ylabel('Multi-hop Energy (Joules)');
% Mark optimal T_energy on both axes
yyaxis left
plot(T_energy, Delay2, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
yyaxis right
plot(T_energy, E_multi2, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
% Add energy threshold line on right axis
yyaxis right
yline(E_threshold, 'k--', 'LineWidth', 1.5);
xlabel('Cycle Period T (seconds)');
title('Energy Constrained Optimization: Delay and Energy vs T');
legend('Delay(T)', 'E_{multi-hop}(T)', 'Optimal T', 'E_{threshold}','Location','best');
grid on;