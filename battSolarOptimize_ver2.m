function [Pgrid, Pbatt, Ebatt] = battSolarOptimize_ver2(N, dt, Ppv, Pload, Einit, Cost, FinalWeight, batteryMinMax)

    % 초기값 설정
    x0 = zeros(3*N, 1);  % PgridV, PbattV, EbattV를 하나의 벡터로 결합

    % 결정 변수 경계 설정 (PgridV, PbattV, EbattV 각각에 대해 설정)
    lb = [-inf * ones(N,1); batteryMinMax.Pmin * ones(N,1); batteryMinMax.Emin * ones(N,1)];
    ub = [inf * ones(N,1); batteryMinMax.Pmax * ones(N,1); batteryMinMax.Emax * ones(N,1)];

    % 비선형 목적 함수 정의
    objective = @(x) costFunction(x, N, dt, Cost, FinalWeight, Ppv, Pload);

    % 비선형 제약 조건 정의
    nonlincon = @(x) nonLinearConstraints(x, N, dt, Einit, batteryMinMax);

    % fmincon 최적화 옵션 설정
    options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'sqp');

    % fmincon 최적화 실행
    [x_opt, ~, exitflag] = fmincon(objective, x0, [], [], [], [], lb, ub, nonlincon, options);

    % 결과값 추출
    Pgrid = x_opt(1:N);
    Pbatt = x_opt(N+1:2*N);
    Ebatt = x_opt(2*N+1:3*N);
end

% 목적 함수 정의
function J = costFunction(x, N, dt, Cost, FinalWeight, Ppv, Pload)
    % 결정 변수 분리
    PgridV = x(1:N);
    PbattV = x(N+1:2*N);
    EbattV = x(2*N+1:3*N);

    % 그리드 비용
    gridCost = dt * Cost' * PgridV;

    % 배터리 마모 비용
    battery_wear_cost = 0;
    for t = 2:N
        battery_wear_cost = battery_wear_cost + E_cap * (PbattV(t) / abs(PbattV(t))) * (phi(EbattV(t)) - phi(EbattV(t-1)));
    end

    % 최종 목적 함수: 그리드 비용 + 배터리 마모 비용 - 최종 배터리 에너지
    J = gridCost - FinalWeight * EbattV(N) + battery_wear_cost;
end

% 비선형 제약 조건 정의
function [c, ceq] = nonLinearConstraints(x, N, dt, Einit, batteryMinMax)
    % 결정 변수 분리
    PgridV = x(1:N);
    PbattV = x(N+1:2*N);
    EbattV = x(2*N+1:3*N);

    % Equality constraints (배터리 에너지 밸런스)
    ceq = zeros(N,1);
    ceq(1) = EbattV(1) - Einit;
    for t = 2:N
        ceq(t) = EbattV(t) - (EbattV(t-1) - PbattV(t-1)*dt);
    end

    % Inequality constraints (충전 및 방전 상태)
    c = zeros(N,1);
    c = [Ppv + PgridV + PbattV - Pload];  % 전력 균형 제약 조건
end

% 배터리 마모 밀도 함수 정의
function w_s = WearDensityFunc(s)
    battPrice = 240000; %[$]
    C_bess_price = battPrice / BattCap;
    eta_ch = 0.95; eta_dis = 0.95;
    A = 694; B = 0.795;

    % Calculate Wear Density func w(s)
    w_s = (C_bess_price / (2 * eta_ch * eta_dis)) * (B * (1 - s)^(B - 1)) / A;
end

% SOC 변화에 따른 phi 함수 정의
function phi_val = phi(EbattV)
    SOC_init = 0.5;
    battenergy = 1000;  % 배터리 에너지 용량 (예시)
    SOC_cur = EbattV / battenergy;
    phi_val = (WearDensityFunc(SOC_init) + WearDensityFunc(SOC_cur)) * (SOC_cur - SOC_init) / 2;
end