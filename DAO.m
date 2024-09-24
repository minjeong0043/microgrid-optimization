function [Pgrid, Pbatt, Ebatt] = DAO(N, Cost, Ppv, Pload)
    % 24hour 기준임.
    prob = optimproblem;
    % Define variables

    PgridV = optimvar('PgridV', N, 'LowerBound', 0);
    SOC = optimvar('SOC', N, 'LowerBound',0.2, 'UpperBound',0.8);
    PattV = optimvar('PbattV', N, 'LowerBound',-400e3, 'UpperBound',400e3);


    % objective func
    prob.ObjectiveSense = 'minimize';
    prob.Objective = K'*Pgrid;

    % Power input/output to battery
    prob.Constraints.energyBalance = optimconstr(N);
    prob.Constraints.energyBalance(1) = EbattV(1) == Einit;
    prob.Constraints.energyBalance(2:N) = EbattV(2:N) == EbattV(1:N-1) - PbattV(1:N-1)*dt;
    
    % Satisfy power load with power from PV, grid and battery
    prob.Constraints.loadBalance = Ppv + PgridV + PbattV == Pload;


    
end