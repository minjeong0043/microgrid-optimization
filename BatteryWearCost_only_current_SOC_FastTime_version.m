% Assume we have SOC array
load SOC.mat
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
    phi_pre;
    [C_bess_unit, phi_pre] = UnitDegCost(SOC.Data(i), phi_pre);
    C_bess = C_bess + C_bess_unit;
    C_bess_array(i) = C_bess;
    disp(i)
end

%% Define function
function w_s = WearDensityFunc(s) 
    % Define parameters
    C_bess_price = 3*10^5; % [$/MWh]
    eta_ch = 0.95; eta_dis = 0.95;
    A = 694; B = 0.795;

    % calculate Wear Density func w(s)
    w_s = (C_bess_price / (2 * eta_ch * eta_dis)) * (B * (1 - s)^(B - 1)) / A;
end

function phi = IntegralWearDensityFunc(SOC_cur)
    % SOC_init와 SOC_cur을 기반으로 수치적 적분 수행
    SOC_init = 50 / 100; % 0-1로 변환
    SOC_cur = SOC_cur / 100;   % 0-1로 변환
    
    % 수치 적분 수행 (사다리꼴 적분법 예시)
    phi = (WearDensityFunc(SOC_init) + WearDensityFunc(SOC_cur)) * (SOC_cur - SOC_init) / 2;
end

function [C_bess_unit, phi_pre] = UnitDegCost(SOC_cur, phi_pre)
    E_cap = 0.8; %[MWh]
    phi_cur = IntegralWearDensityFunc(SOC_cur);
    C_bess_unit = E_cap * (phi_cur - phi_pre);
    phi_pre = phi_cur;

    % Wear Cost is always positive whenever battery is charging or discharging
    C_bess_unit = double(abs(C_bess_unit));
end