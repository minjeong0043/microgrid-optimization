function C_bess = BatteryDegradationCost(SOC_cur, BattCap)
    % MATLAB Function 블록에서는 모든 변수를 입력 및 출력으로 정의해야 합니다.
    % 따라서 phi_pre와 C_bess는 persistent로 정의하여 상태를 유지합니다.
    
    persistent SOC_pre C_bess_accum;
    
    % 초기화
    if isempty(SOC_pre)
        SOC_pre = 0.5;
    end
    if isempty(C_bess_accum)
        C_bess_accum = 0;
    end
    SOC_cur = SOC_cur / 100;

    % 새로 계산된 단위 비용을 phi_pre와 함께 업데이트
    C_bess_unit = UnitDegCost2(SOC_cur, SOC_pre);
    
    % 누적 비용을 업데이트
    C_bess_accum = C_bess_accum + C_bess_unit;
    
    % 누적된 C_bess 값을 출력
    C_bess = C_bess_accum;
    
    % SOC_pre를 업데이트
    SOC_pre = SOC_cur;

    % Define function for Wear Density
    function w_s = WearDensityFunc(s)
        % Define parameters
        %C_bess_price = 3*10^5; % [$/MWh]
        %C_bess_price = 10000/16;
        battPrice = 240000; %[$]
        C_bess_price = battPrice / BattCap;
        eta_ch = 0.95; eta_dis = 0.95;
        A = 694; B = 0.795;

        % Calculate Wear Density func w(s)
        w_s = (C_bess_price / (2 * eta_ch * eta_dis)) * (B * (1 - s)^(B - 1)) / A;
    end

    % Integral of Wear Density Function (Trapezoidal Approximation)
    function phi = IntegralWearDensityFunc(SOC_cur)
        SOC_init = 50 / 100; % Convert to fraction (0-1)
        SOC_cur = SOC_cur / 100;   % Convert to fraction (0-1)
        
        % Trapezoidal numerical integration approximation
        phi = (WearDensityFunc(SOC_init) + WearDensityFunc(SOC_cur)) * (SOC_cur - SOC_init) / 2;
    end

    % Unit degradation cost calculation
    function C_bess_unit = UnitDegCost(SOC_cur, phi_pre)
        %E_cap = 0.8; % [MWh]
        %E_cap = battEnergy;
        E_cap = BattCap;
        phi_cur = IntegralWearDensityFunc(SOC_cur);
        C_bess_unit = E_cap * (phi_cur - phi_pre);
        
        % Wear Cost is always positive
        C_bess_unit = abs(C_bess_unit);
    end

    %% version 2 code: integral soct, soct-1
    function phi = IntegralWearDensityFunc2(SOC_pre, SOC_cur)
        % Trapezoidal numerical integration approximation
        phi = (WearDensityFunc(SOC_pre) + WearDensityFunc(SOC_cur)) * (SOC_cur - SOC_pre) / 2;
    end
    function C_bess_unit = UnitDegCost2(SOC_cur, SOC_pre)
        E_cap = BattCap; %[MWh]
        %E_cap = 9.000000000000000e+09;
        C_bess_unit = E_cap* IntegralWearDensityFunc2(SOC_pre, SOC_cur);
        
        % Wear Cost is always positive
        C_bess_unit = abs(C_bess_unit);
    end

end
