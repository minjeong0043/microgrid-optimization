function [Pgrid,Pbatt,Ebatt] = battSolarOptimize_ver2(N,dt,Ppv,Pload,Einit,Cost,FinalWeight,batteryMinMax, c, d)

% Minimize the cost of power from the grid while meeting load with power 
% from PV, battery and grid 
% fprintf("c = %f, ", c)
% fprintf("d = %f\n", d)
prob = optimproblem;

% Decision variables
PgridV = optimvar('PgridV',N);
PbattV = optimvar('PbattV',N,'LowerBound',batteryMinMax.Pmin,'UpperBound',batteryMinMax.Pmax);
EbattV = optimvar('EbattV',N,'LowerBound',batteryMinMax.Emin,'UpperBound',batteryMinMax.Emax);
L = optimvar('L', N); %  하한 설정해서 값 안 나오면 하한 설정 지워보기.
Q = optimvar('Q', N, 'LowerBound',0);
% Minimize cost of electricity from the grid
prob.ObjectiveSense = 'minimize';
prob.Objective = dt*Cost'*PgridV - FinalWeight*EbattV(N) + (L(N) - L(N-1));

% Power input/output to battery
prob.Constraints.energyBalance = optimconstr(N);
prob.Constraints.energyBalance(1) = EbattV(1) == Einit;
prob.Constraints.energyBalance(2:N) = EbattV(2:N) == EbattV(1:N-1) - PbattV(1:N-1)*dt;

% Define Lfunc
prob.Constraints.L = optimconstr(N);
prob.Constraints.L(1:N) = L(1:N) == 1/2 * (Q(1:N)).^2;

% Define Q
Cd = 2400000 / 2500; % [$/KWh]
prob.Constraints.Qfunc = optimconstr(N);
prob.Constraints.Qfunc(1) = Q(1) == 0;
% prob.Constraints.Qfunc(2:N) = Q(2:N) == max(Q(1:N-1) - Cd*(PgridV(1:N-1)+Pload(1:N-1)), 0);
prob.Constraints.Qfunc(2:N) = Q(2:N) == Q(1:N-1) - Cd*(PgridV(1:N-1)+Pload(1:N-1));
% Satisfy power load with power from PV, grid and battery
prob.Constraints.loadBalance = Ppv + PgridV + PbattV == Pload;

% initial sturcture
x0.PgridV = zeros(N,1);
x0.PbattV = zeros(N,1);
x0.EbattV = Einit * ones(N,1);
x0.L = zeros(N,1);
x0.Q = zeros(N,1);

% Solve the linear program
options = optimoptions(prob.optimoptions,'Display','none');
[values,~,exitflag] = solve(prob, x0,'Options',options);

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
