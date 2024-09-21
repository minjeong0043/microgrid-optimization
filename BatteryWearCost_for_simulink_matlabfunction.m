function C_bess = BatteryDegradationCost(SOC)
    % MATLAB Function 블록에서는 모든 변수를 입력 및 출력으로 정의해야 합니다.
    % 따라서 phi_pre와 C_bess는 persistent로 정의하여 상태를 유지합니다.
    
    persistent phi_pre C_bess_accum;
    
    % 초기화
    if isempty(phi_pre)
        phi_pre = 0;
    end
    if isempty(C_bess_accum)
        C_bess_accum = 0;
    end

    % 새로 계산된 단위 비용을 phi_pre와 함께 업데이트
    C_bess_unit = UnitDegCost(SOC, phi_pre);
    
    % 누적 비용을 업데이트
    C_bess_accum = C_bess_accum + C_bess_unit;
    
    % 누적된 C_bess 값을 출력
    C_bess = C_bess_accum;
    
    % phi_pre를 업데이트
    phi_pre = IntegralWearDensityFunc(SOC);

    % Define function for Wear Density
    function w_s = WearDensityFunc(s)
        % Define parameters
        C_bess_price = 3*10^5; % [$/MWh]
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
        E_cap = 0.8; % [MWh]
        phi_cur = IntegralWearDensityFunc(SOC_cur);
        C_bess_unit = E_cap * (phi_cur - phi_pre);
        
        % Wear Cost is always positive
        C_bess_unit = abs(C_bess_unit);
    end
end