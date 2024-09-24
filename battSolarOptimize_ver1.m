function [Pgrid,Pbatt,Ebatt] = battSolarOptimize(N,dt,Ppv,Pload,Einit,Cost,FinalWeight,batteryMinMax)

% Minimize the cost of power from the grid while meeting load with power 
% from PV, battery and grid 

prob = optimproblem;

% Decision variables
PgridV = optimvar('PgridV',N);
PbattV = optimvar('PbattV',N,'LowerBound',batteryMinMax.Pmin,'UpperBound',batteryMinMax.Pmax);
EbattV = optimvar('EbattV',N,'LowerBound',batteryMinMax.Emin,'UpperBound',batteryMinMax.Emax);
BattWearCost = optimvar('BattWearCost', N, 'LowerBound', 0);

% Minimize cost of electricity from the grid
prob.ObjectiveSense = 'minimize';
prob.Objective = dt * Cost' * PgridV - FinalWeight * EbattV(N) + BattWearCost(N);

% Power input/output to battery
prob.Constraints.energyBalance = optimconstr(N);
prob.Constraints.energyBalance(1) = EbattV(1) == Einit;
prob.Constraints.energyBalance(2:N) = EbattV(2:N) == EbattV(1:N-1) - PbattV(1:N-1)*dt;

% battery Wear Cost input/output
E_cap = 2500;
prob.Constraints.battDeg = optimconstr(N);
prob.Constraints.battDeg(1) = BattWearCost(1) == 0;
prob.Constraints.battDeg(2:N) = BattWearCost(2:N) == BattWearCost(1:N-1) + E_cap * (phi(EbattV(2:N)) - phi(EbattV(1:N-1)));

% Satisfy power load with power from PV, grid and battery
prob.Constraints.loadBalance = Ppv + PgridV + PbattV == Pload;

% initial sturcture
x0.PgridV = zeros(N,1);
x0.PbattV = zeros(N,1);
x0.EbattV = Einit * ones(N,1);
x0.BattWearCost = zeros(N, 1);

% Solve the linear program
options = optimoptions(prob.optimoptions,'Display','none');
%options = optimoptions('fmincon', 'Algorithm', 'trust-region-reflective','Display','none');
[values,~,exitflag] = solve(prob,x0,'Options',options);

% Parse optimization results
if exitflag <= 0
    % 최적해 없거나 오류는 0을 반환함
    Pgrid = zeros(N,1);
    Pbatt = zeros(N,1);
    Ebatt = zeros(N,1);
else
    % 최적해 찾았을 때 값을 넣어줌
    Pgrid = values.PgridV;
    Pbatt = values.PbattV;
    Ebatt = values.EbattV;
end
end
function w_s = WearDensityFunc(s)
    % Define parameters
    %C_bess_price = 3*10^5; % [$/MWh]
    %C_bess_price = 10000/16;
    BattCap = 2500;
    battPrice = 240000; %[$]
    C_bess_price = battPrice / BattCap;
    eta_ch = 0.95; eta_dis = 0.95;
    A = 694; B = 0.795;

    % Calculate Wear Density func w(s)
    w_s = (C_bess_price / (2 * eta_ch * eta_dis)) * (B * (1 - s)^(B - 1)) / A;
end
function phi = phi(EbattV)
    battEnergy = 9*10^9;
    SOC_init = 0.5;
    SOC_cur = EbattV / battEnergy;
    N = 241;
    for t = 2:N-1
        phi = (WearDensityFunc(SOC_init) + WearDensityFunc(SOC_cur(t))) * (SOC_cur(t) - SOC_init) / 2;
    end
% phi 값을 계산 (배터리 마모 밀도 함수 적용)
%     phi_val = zeros(length(SOC_cur), 1);
%     for t = 2:1:length(SOC_cur)
%         phi_val(t) = (WearDensityFunc(SOC_init) + WearDensityFunc(SOC_cur(t))) * (SOC_cur(t) - SOC_init) / 2;
%     end
end

    