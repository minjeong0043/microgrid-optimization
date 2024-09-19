% Assume we have SOC array
w_s = WearDensityFunc(0.1);
C_bess_unit = UnitDegCost(50);
C_bess = 0;

index = length(SOC.Data);

C_bess_array = zeros(1, index)
for i = 2:index-1
    C_bess_unit = UnitDegCost(i);
    C_bess = C_bess + C_bess_unit
    C_bess_array(i) = C_bess;
%     disp(i)
end

figure(1)
plot(C_bess_array)
% Define function
function w_s = WearDensityFunc(s)
    % Define parameters
    C_bess_price = 3*10^5; % [MWh]
    eta_ch = 0.95; eta_dis = 0.95;
    A = 694; B = 0.795;

    % Calculate wear density func w(s)
    w_s = (C_bess_price / (2* eta_ch * eta_dis)) * (B * (1 - s)^(B - 1)) / A;
end

function phi = IntegralWearDensityFunc(i) % i is index of SOC
    syms s
    load SOC.mat
    phi = int(WearDensityFunc(s), SOC.Data(1), SOC.Data(i)); % 여기서 확인해봐야 할 거는 초기값이 달라도 C_bess값이 달라지는지 같은지 임. 초기값 바꿔가면서 비교해보기
end

function C_bess_unit = UnitDegCost(i)
    E_cap = 0.8; % [MWh]
    C_bess_unit = E_cap * (IntegralWearDensityFunc(i) - IntegralWearDensityFunc(i-1));

    % Wear cost is always positive whenever battery is charging or discharging
    C_bess_unit = double(abs(C_bess_unit));
end
