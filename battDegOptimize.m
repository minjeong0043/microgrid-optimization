function [Pgrid,Pbatt,Ebatt] = battDegOptimize(N,dt,Ppv,Pload,Einit,Cost,FinalWeight,batteryMinMax)

% Minimize the cost of power from the grid while meeting load with power 
% from PV, battery and grid 

prob = optimproblem;

% Decision variables
PgridV = optimvar('PgridV',N);
PbattV = optimvar('PbattV',N,'LowerBound',batteryMinMax.Pmin,'UpperBound',batteryMinMax.Pmax);
EbattV = optimvar('EbattV',N,'LowerBound',batteryMinMax.Emin,'UpperBound',batteryMinMax.Emax); %이걸로 SOC예측 가능


fprintf("EbattV(N) : ", EbattV(N))
% Define parameter
battPrice = 240000; %[$]
BattCap = 2500; %[kWh]
C_bess_price = battPrice / BattCap;
eta_ch = 0.95; eta_dis = 0.95;
A = 694; B = 0.795;
battEnergy = 9.000000000000000e+09;

% Minimize cost of electricity from the grid
prob.ObjectiveSense = 'minimize';
%prob.Objective = dt*Cost'*PgridV - FinalWeight*EbattV(N) + (PbattV / 400000) * (BattCap * (((C_bess_price / (2 * eta_ch * eta_dis)) * (B * (1 - SOC_pre)^(B - 1)) / A) + ((C_bess_price / (2 * eta_ch * eta_dis)) * (B * (1 - EbattV(N) / battEnergy).^(B - 1)) / A)) * (EbattV(N) / battEnergy - SOC_pre)/ 2);
prob.Objective = dt*Cost'*PgridV - FinalWeight*EbattV(N) + battCap * ((C_bess_price / (2*eta_ch*eta_dis)) * (B * (1-EbattV / battEnergy)^(B-1))/A);

%SOC_pre = EbattV(N) / battEnergy;
% Power input/output to battery
prob.Constraints.energyBalance = optimconstr(N);
prob.Constraints.energyBalance(1) = EbattV(1) == Einit;
prob.Constraints.energyBalance(2:N) = EbattV(2:N) == EbattV(1:N-1) - PbattV(1:N-1)*dt;

% Satisfy power load with power from PV, grid and battery
prob.Constraints.loadBalance = Ppv + PgridV + PbattV == Pload;

% Solve the linear program
options = optimoptions(prob.optimoptions,'Display','none');
[values,~,exitflag] = solve(prob,'Options',options);

% Parse optmization results
if exitflag <= 0
    Pgrid = zeros(N,1);
    Pbatt = zeros(N,1);
    Ebatt = zeros(N,1);
else
    Pgrid = values.PgridV;
    Pbatt = values.PbattV;
    Ebatt = values.EbattV;
end
