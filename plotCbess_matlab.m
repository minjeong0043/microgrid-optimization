% w(s) via s
SOC = Ebatt / battEnergy;

figure(1)
subplot(2,1,1)
plot(SOC)

Cbessl = Cbess(length(SOC), SOC)
subplot(2,1,2)
plot(Cbessl)

%% Define function
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
function phi = phi(SOC)
    battEnergy = 9*10^9;
    SOC_init = 0.5;
    %SOC_cur = EbattV / battEnergy;
    N = 241;
    for t = 2:N-1
        phi = (WearDensityFunc(SOC_init) + WearDensityFunc(SOC)) * (SOC - SOC_init) / 2;
    end
end
function Cbess = totalCost(SOC, SOC_pre)
    Cbess = abs(2500 * (phi(SOC) - phi(SOC_pre)));
end
function Cbess = Cbess(N, SOC)
    Cbess = zeros(N,1);
    Cbess(1,1) = 0;
    for i = 2:N-1
        Cbess(i,1) = Cbess(i-1,1) + totalCost(SOC(i), SOC(i-1));
    end
    Cbess(N,1) = Cbess(N-1,1);
end
