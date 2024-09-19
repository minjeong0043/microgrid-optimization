% Assume we don't have SOC array, only have current SOC value

SOC_0 = 0.2; SOC_t = 0.3; SOC_t_1 = 0.1;
C_bess = 0;
phi_20_30 = IntegralWearDensityFunc(SOC_0, SOC_t);% charging; positive value
phi_20_10 = IntegralWearDensityFunc(SOC_0, SOC_t_1);% discharging; negative value

C_bess_unit = UnitDegCost(SOC_0, SOC_t, SOC_t_1);
C_bess_unit_1 = UnitDegCost(SOC_0, SOC_t_1, SOC_t);
C_bess = C_bess + C_bess_unit;
disp(C_bess) %syms로 더 정확한 계산을 위함
disp(double(C_bess)) % 소수점으로 간단하게 표현 가능
% if isAlways(C_bess_unit > 0)
%     disp("C_bess_unit is positive")
% else
%     disp("C_bess_unit is negative")
% end
% if isAlways(C_bess_unit_1 > 0)
%     disp("C_bess_unit is positive")
% else
%     disp("C_bess_unit is negative")
% end
% if isAlways(phi_20_30 > 0)
%     disp("phi_20_30 is positive")
% else
%     disp("phi_20_30 is negative")
% end
% 
% if isAlways(phi_20_10 > 0)
%     disp("phi_20_10 is positive")
% else
%     disp("phi_20_10 is negative")
% end
% 
% if isAlways(phi_20_10> phi_20_30)
%     disp("value of phi_20_10 is bigger than -. ")
% else
%     disp("value of phi_20_10 is smaller than -.")
% end
% 
% 


%% Define function
function w_s = WearDensityFunc(s)
    % define parameters
    C_bess_price = 3*10^5; %[MWh]
    eta_ch = 0.95; eta_dis = 0.95;
    A = 694; B = 0.795;
    
    % calculate wear density func w(s)
    w_s = (C_bess_price / (2 * eta_ch * eta_dis)) * (B * (1 - s)^(B - 1)) / A;
end


function phi =  IntegralWearDensityFunc(SOC_0, SOC_i)
    syms s
    phi = int(WearDensityFunc(s), SOC_0, SOC_i);
end

function C_bess_unit = UnitDegCost(SOC_0, SOC_t, SOC_t_1)
    E_cap = 0.8; %[MWh]
    C_bess_unit = E_cap * (IntegralWearDensityFunc(SOC_0, SOC_t) - IntegralWearDensityFunc(SOC_0, SOC_t_1));

    % wear cost is always positive whenever battery is charging or discharging
    C_bess_unit = abs(C_bess_unit);
end
