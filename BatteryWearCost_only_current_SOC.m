% Assume we have SOC array
phi_pre = 0;
%w_s = WearDensityFunc(0.1);
% disp("phi_pre 1: ")
% disp(phi_pre)
%index = 4;
% [C_bess_unit, phi_pre] = UnitDegCost(SOC.Data(index), phi_pre);
% disp("phi_pre 2: ")
% disp(phi_pre)
C_bess = 0;

% SOC.Data(index)

index = length(SOC.Data);

C_bess_array = zeros(1, index);
for i = 2:100:index
    phi_pre
    [C_bess_unit, phi_pre] = UnitDegCost(SOC.Data(i), phi_pre);
    C_bess = C_bess + C_bess_unit
    C_bess_array(i) = C_bess;
    disp(i)
end

%% Define function
function w_s = WearDensityFunc(s) % 얘는 단순히 계산하는 수식을 표현한 것.
    % Define parameters
    C_bess_price = 3*10^5; % [$/MWh]
    eta_ch = 0.95; eta_dis = 0.95;
    A = 694; B = 0.795;

    % calculate Wear Density func w(s)
    w_s = (C_bess_price / (2 * eta_ch * eta_dis)) * (B * (1 - s)^(B - 1)) / A;
end

function phi = IntegralWearDensityFunc(SOC_cur)
    % i : variable SOC index
    % 현재의  SOC값만 받아와서 계산해야 하는 것.
    % SOC_init, SOC_cur : Initial SOC and Current SOC
    syms s
    SOC_init = 50 / 100;
    SOC_cur = SOC_cur / 100;
    phi = int(WearDensityFunc(s), SOC_init, SOC_cur);
end

function [C_bess_unit, phi_pre] = UnitDegCost(SOC_cur, phi_pre)
    E_cap = 0.8; %[MWh]
    C_bess_unit = E_cap * (IntegralWearDensityFunc(SOC_cur) - phi_pre);
%     disp('phi_pre')
%     disp(phi_pre)
    phi_pre = IntegralWearDensityFunc(SOC_cur);

    % Wear Cost is always positive whenever battery is charging or discharging
    C_bess_unit = double(abs(C_bess_unit))
end