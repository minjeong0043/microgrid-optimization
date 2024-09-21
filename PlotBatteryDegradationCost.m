% figure(1)
% subplot(2,1,1)
% plot(SOC.Data)
% subplot(2,1,2)
% plot(C_bess_array)

figure(1)
subplot(2,1,1)
scatter(1:length(SOC.Data), SOC.Data, 'filled')  % SOC 데이터를 점으로 표시
title('SOC Data')
xlabel('Index')
ylabel('SOC')

subplot(2,1,2)
scatter(1:length(C_bess_array), C_bess_array, 'filled')  % C_bess_array 데이터를 점으로 표시
title('C_bess Array')
xlabel('Index')
ylabel('C_bess')


disp(C_bess_array(end))