load pvLoadPriceData.mat;
load Ebatt.mat;
costDataOffset = costData + 5; %offset을 왜 넣는 걸까요?

% Microgrid Settings
panelArea = 2500;
panelEff = 0.3;
loadBase = 350e3;
BattCap = 2500;     % Energy Storage Rated Capacity [kWh]
batteryMinMax.Pmin = -400e3;    % Max Discharge Rate [W]
batteryMinMax.Pmax = 400e3;     % Max Charge Rate [W]

% Online optimization parameters
FinalWeight = 1;    % Final weight on energy storage
timeOptimize = 5;    % Time step for optimization [min]
timePred = 20;        % Predict ahead horizon [hours]

% Compute PV Array Power Output
cloudyPpv = panelArea*panelEff*cloudyDay; % amp단위 바꿔주는 듯
clearPpv = panelArea*panelEff*clearDay;

% Select Load Profile
loadSelect = 1;
loadFluc = loadData(:, loadSelect);

% Battery SOC Energy constraints (keep between 20%-80% SOC)
battEnergy = 3.6e6*BattCap;
batteryMinMax.Emax = 0.8*battEnergy;
batteryMinMax.Emin = 0.2*battEnergy;

% Setup Optimization time vector
optTime = timeOptimize*60; % 얘도 초단위로 바꿔주는 듯. 모든 것을 초 단위로
stepAdjust = (timeOptimize*60)/(time(2)-time(1)); % 최적화 timestep이 5분인데 기록Data의 시간 단위는 60초이므로 5칸씩 움직일 때마다 최적화 진행됨.
N = numel(time(1:stepAdjust: end))-1; %time이 60초 단위로 1441개인데 300초 단위로 하면 몇 개인지 구하는 것.
tvec = (1:N)'*optTime; %20시간을 300초 단위로 나타냄. length(tvec) = 241, 그니까 5분을 20시간 나타내면 240개 되는 거임.

% Horizon for "sliding" optimization
M = find(tvec > timePred*3600, 1, 'first'); %그니까 이건 예측 시간이 20시간인데 20시간까지 예측하고 그 이후의 값의 index을 구하는 것
numDays =2; %이건 뭔데
loadSelect = 3;
clearPpvVec = panelArea*panelEff*repmat(clearDay(2:stepAdjust:end), numDays,1); %repmat으로 행 2개 열 1개로 저 데이터 2개가 연속으로 나옴 길이도 2배됨.
loadSelect = 3;

% 길이 2배로 늘이기 
for loadSelect = 1:4
    loadDataOpt(:, loadSelect) = repmat(loadData(2:stepAdjust:end, loadSelect), numDays, 1);
end
C = repmat(costData(2:stepAdjust:end), numDays, 1);
% disp(length(C)) % 576 = 2* 288
% disp(length(costData)) % 1441 = 24 * 60
Ebatt = repmat(Ebatt, numDays, 1);
% length(Ebatt)



% N이 전체 데이터를 최적 타입스텝으로 나눈 개수
% M이 예측할 만큼 시간 동안의 데이터 개수

CostMat = zeros(N,M);
PpvMat = zeros(N,M);
PloadMat = zeros(N,M);
EbattMat = zeros(N,M);

% Construct forecast vectors for optimization (N x M) matrix
for i = 1:N % N은 24시간
    CostMat(i, :) = C(i:i+M-1);
    PpvMat(i, :) = clearPpvVec(i:i+M-1);
    PloadMat(i, :) = loadDataOpt(i:i+M-1, loadSelect);
    EbattMat(i, :) = Ebatt(i:i+M-1);
end

% figure(1)
% plot(CostMat)

% figure(1)
% plot(EbattMat)

% 위에 Mat은 Mtx임

CostForecast.time = tvec; % 24시간을 5분 단위로 
CostForecast.signals.values = CostMat;
CostForecast.signals.dimensions = M;

PpvForecast.time = tvec;
PpvForecast.signals.values = PpvMat;
PpvForecast.signals.dimensions = M;

PloadForecast.time = tvec;
PloadForecast.signals.values = PloadMat;
PloadForecast.signals.dimensions = M;

EbattForecast.time = tvec;
EbattForecast.signals.values = EbattMat;
EbattForecast.signals.dimensions = M;

%Clean up unneeded Variables
clear clearDay cloudyDay BattCap panelArea panelEff loadBase;
clear M N i loadSelect numDays stepAdjust timeOptimize;
clear CostMat PloadMat PpvMat EbattMat clearPpvVec C Ebatt;
clear batteryMinMax timePred tvec loadData loadDataOpt FinalWeight
