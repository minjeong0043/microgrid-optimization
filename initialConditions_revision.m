load pvLoadPriceData.mat;
load Ebatt.mat;
costDataOffset = costData + 5; %offset�� �� �ִ� �ɱ��?

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
cloudyPpv = panelArea*panelEff*cloudyDay; % amp���� �ٲ��ִ� ��
clearPpv = panelArea*panelEff*clearDay;

% Select Load Profile
loadSelect = 1;
loadFluc = loadData(:, loadSelect);

% Battery SOC Energy constraints (keep between 20%-80% SOC)
battEnergy = 3.6e6*BattCap;
batteryMinMax.Emax = 0.8*battEnergy;
batteryMinMax.Emin = 0.2*battEnergy;

% Setup Optimization time vector
optTime = timeOptimize*60; % �굵 �ʴ����� �ٲ��ִ� ��. ��� ���� �� ������
stepAdjust = (timeOptimize*60)/(time(2)-time(1)); % ����ȭ timestep�� 5���ε� ���Data�� �ð� ������ 60���̹Ƿ� 5ĭ�� ������ ������ ����ȭ �����.
N = numel(time(1:stepAdjust: end))-1; %time�� 60�� ������ 1441���ε� 300�� ������ �ϸ� �� ������ ���ϴ� ��.
tvec = (1:N)'*optTime; %20�ð��� 300�� ������ ��Ÿ��. length(tvec) = 241, �״ϱ� 5���� 20�ð� ��Ÿ���� 240�� �Ǵ� ����.

% Horizon for "sliding" optimization
M = find(tvec > timePred*3600, 1, 'first'); %�״ϱ� �̰� ���� �ð��� 20�ð��ε� 20�ð����� �����ϰ� �� ������ ���� index�� ���ϴ� ��
numDays =2; %�̰� ����
loadSelect = 3;
clearPpvVec = panelArea*panelEff*repmat(clearDay(2:stepAdjust:end), numDays,1); %repmat���� �� 2�� �� 1���� �� ������ 2���� �������� ���� ���̵� 2���.
loadSelect = 3;

% ���� 2��� ���̱� 
for loadSelect = 1:4
    loadDataOpt(:, loadSelect) = repmat(loadData(2:stepAdjust:end, loadSelect), numDays, 1);
end
C = repmat(costData(2:stepAdjust:end), numDays, 1);
% disp(length(C)) % 576 = 2* 288
% disp(length(costData)) % 1441 = 24 * 60
Ebatt = repmat(Ebatt, numDays, 1);
% length(Ebatt)



% N�� ��ü �����͸� ���� Ÿ�Խ������� ���� ����
% M�� ������ ��ŭ �ð� ������ ������ ����

CostMat = zeros(N,M);
PpvMat = zeros(N,M);
PloadMat = zeros(N,M);
EbattMat = zeros(N,M);

% Construct forecast vectors for optimization (N x M) matrix
for i = 1:N % N�� 24�ð�
    CostMat(i, :) = C(i:i+M-1);
    PpvMat(i, :) = clearPpvVec(i:i+M-1);
    PloadMat(i, :) = loadDataOpt(i:i+M-1, loadSelect);
    EbattMat(i, :) = Ebatt(i:i+M-1);
end

% figure(1)
% plot(CostMat)

% figure(1)
% plot(EbattMat)

% ���� Mat�� Mtx��

CostForecast.time = tvec; % 24�ð��� 5�� ������ 
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
