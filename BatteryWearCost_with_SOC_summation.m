% Integral 말고 summation으로 하면 계산이 빨라지지 않을까
w_s = WearDensityFunc(0.1);
C_bess_unit = UnitDegCost(50);
C_bess = 0

index = length(SOC.Data);

C_bess_array = zeros(1, index);
for i = 2:index-1
    C_bess_unit = UnitDegCost(i);
    C_bess = C_bess + C_bess_unit
    C_bess_array(i) = C_bess;
%     disp(i)
end

%% Define function
function w_s = WearDensityFunc(s)
    %define parameters
    C_bess_price = 3*10^5;
    eta_ch = 0.95; eta_dis = 0.95;
    A = 694; B = 0.795;

    w_s = (C_bess_price / (2* eta_ch * eta_dis)) * (B * (1 - s)^(B - 1)) / A;
end

% function phi = SumWearDensityFunc(i)
%     syms s
%     load SOC.mat
%     phi = symsum(WearDensityFunc(s), s, SOC.Data(1), SOC.Data(i));
% end

function phi = SumWearDensityFunc(i)
    load SOC.mat
    phi = 0;
    for idx = 2:i
        s = SOC.Data(idx);
        phi = phi + WearDensityFunc(s);
    end
end

function C_bess_unit = UnitDegCost(i)
    E_cap = 0.8; % [MWh]
    C_bess_unit = E_cap * (SumWearDensityFunc(i) - SumWearDensityFunc(i-1));

    % Wear cost is always positive whenever battery is charging or discharging
    C_bess_unit = double(abs(C_bess_unit));
end