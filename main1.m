% 主程序：NOMA系统功率分配算法比较
% 作者：asaqe with AI   
% 日期：2024年11月19日  

clc
clear
close all

% 设置中文显示
set(0,'DefaultAxesFontName','SimHei');
set(0,'DefaultTextFontName','SimHei');

% 系统参数设置
num_users = 2;            % 每组两个用户
total_power = 1.0;        % 总功率1W
bandwidth = 1e6;          % 带宽1MHz
noise_power = 1e-12;      % 噪声功率
num_simulations = 1000;   % 仿真次数

% 创建功率分配实例
pa = PowerAllocation(total_power, noise_power, bandwidth);

% 初始化结果存储
throughput_results = zeros(num_simulations, 4);  % 存储每次仿真的吞吐量
fairness_results = zeros(num_simulations, 4);    % 存储每次仿真的公平性
runtime_results = zeros(num_simulations, 4);     % 存储每次仿真的运行时间

% 多次仿真
for n = 1:num_simulations
    % 生成两个用户的信道增益
    d = 10 + 90 * rand(1, 2);  % 用户距离基站 10-100m
    path_loss_dB = 128.1 + 37.6 * log10(d/1000);  % 3GPP路径损耗模型
    path_loss = 10.^(-path_loss_dB/10);  % 转换为线性尺度
    rayleigh = abs(complex(randn(1,2), randn(1,2))).^2 / 2;
    channel_gains = path_loss .* rayleigh;
    
    % 比较不同功率分配算法
    [power_fspa, time_fspa] = pa.FSPA(channel_gains);
    [power_fpa, time_fpa] = pa.FPA(channel_gains);
    [power_ftpa, time_ftpa] = pa.FTPA(channel_gains);
    [power_max, time_max] = pa.MaxThroughput(channel_gains);

    % 计算性能指标
    % 1. 吞吐量
    throughput_fspa = pa.calculate_throughput(channel_gains, power_fspa);
    throughput_fpa = pa.calculate_throughput(channel_gains, power_fpa);
    throughput_ftpa = pa.calculate_throughput(channel_gains, power_ftpa);
    throughput_max = pa.calculate_throughput(channel_gains, power_max);
    
    % 2. 公平性
    [sorted_gains, idx] = sort(channel_gains, 'descend');

    % FSPA
    sorted_powers_fspa = power_fspa(idx);
    sinr1_fspa = (sorted_powers_fspa(1) * sorted_gains(1)) / noise_power;
    sinr2_fspa = (sorted_powers_fspa(2) * sorted_gains(2)) / (sorted_powers_fspa(1) * sorted_gains(2) + noise_power);
    rates_fspa = bandwidth * log2(1 + [sinr1_fspa, sinr2_fspa]);

    % FPA
    sorted_powers_fpa = power_fpa(idx);
    sinr1_fpa = (sorted_powers_fpa(1) * sorted_gains(1)) / noise_power;
    sinr2_fpa = (sorted_powers_fpa(2) * sorted_gains(2)) / (sorted_powers_fpa(1) * sorted_gains(2) + noise_power);
    rates_fpa = bandwidth * log2(1 + [sinr1_fpa, sinr2_fpa]);

    % FTPA
    sorted_powers_ftpa = power_ftpa(idx);
    sinr1_ftpa = (sorted_powers_ftpa(1) * sorted_gains(1)) / noise_power;
    sinr2_ftpa = (sorted_powers_ftpa(2) * sorted_gains(2)) / (sorted_powers_ftpa(1) * sorted_gains(2) + noise_power);
    rates_ftpa = bandwidth * log2(1 + [sinr1_ftpa, sinr2_ftpa]);

    % MaxThroughput
    sorted_powers_max = power_max(idx);
    sinr1_max = (sorted_powers_max(1) * sorted_gains(1)) / noise_power;
    sinr2_max = (sorted_powers_max(2) * sorted_gains(2)) / (sorted_powers_max(1) * sorted_gains(2) + noise_power);
    rates_max = bandwidth * log2(1 + [sinr1_max, sinr2_max]);
    
    fairness_fspa = pa.calculate_fairness(rates_fspa);
    fairness_fpa = pa.calculate_fairness(rates_fpa);
    fairness_ftpa = pa.calculate_fairness(rates_ftpa);
    fairness_max = pa.calculate_fairness(rates_max);
    
    % 存储结果
    throughput_results(n,:) = [throughput_fspa, throughput_fpa, throughput_ftpa, throughput_max];
    fairness_results(n,:) = [fairness_fspa, fairness_fpa, fairness_ftpa, fairness_max];
    runtime_results(n,:) = [time_fspa, time_fpa, time_ftpa, time_max];
end

% 计算平均值和标准差
mean_throughput = mean(throughput_results);
std_throughput = std(throughput_results);
mean_fairness = mean(fairness_results);
std_fairness = std(fairness_results);
mean_runtime = mean(runtime_results);

% 1. 吞吐量比较图
figure('Name', '系统吞吐量比较', 'Renderer', 'painters');
bar_data = mean_throughput;
b = bar(bar_data);
hold on;
errorbar(1:4, bar_data, std_throughput, 'k', 'LineStyle', 'none');
set(gca, 'XTickLabel', {'FSPA', 'FPA', 'FTPA', 'MaxThroughput'});
title('系统吞吐量比较');
ylabel('平均系统吞吐量 (bps)');
grid on;

% 2. 公平性比较图
figure('Name', '系统公平性比较', 'Renderer', 'painters');
bar_data = mean_fairness;
b = bar(bar_data);
hold on;
errorbar(1:4, bar_data, std_fairness, 'k', 'LineStyle', 'none');
set(gca, 'XTickLabel', {'FSPA', 'FPA', 'FTPA', 'MaxThroughput'});
title('系统公平性比较');
ylabel('平均系统公平性');
grid on;

% 3. 运行时间比较图
figure('Name', '算法运行时间比较', 'Renderer', 'painters');
bar(mean_runtime);
set(gca, 'XTickLabel', {'FSPA', 'FPA', 'FTPA', 'MaxThroughput'});
title('算法运行时间比较');
ylabel('平均运行时间 (秒)');
grid on;

% 打印统计结果
fprintf('\n====== 功率分配算法性能统计 ======\n');
fprintf('平均系统吞吐量 (bps):\n');
fprintf('FSPA: %.2e (±%.2e)\n', mean_throughput(1), std_throughput(1));
fprintf('FPA: %.2e (±%.2e)\n', mean_throughput(2), std_throughput(2));
fprintf('FTPA: %.2e (±%.2e)\n', mean_throughput(3), std_throughput(3));
fprintf('MaxThroughput: %.2e (±%.2e)\n', mean_throughput(4), std_throughput(4));

fprintf('\n平均系统公平性:\n');
fprintf('FSPA: %.4f (±%.4f)\n', mean_fairness(1), std_fairness(1));
fprintf('FPA: %.4f (±%.4f)\n', mean_fairness(2), std_fairness(2));
fprintf('FTPA: %.4f (±%.4f)\n', mean_fairness(3), std_fairness(3));
fprintf('MaxThroughput: %.4f (±%.4f)\n', mean_fairness(4), std_fairness(4));

fprintf('\n平均运行时间 (秒):\n');
fprintf('FSPA: %.4f\n', mean_runtime(1));
fprintf('FPA: %.4f\n', mean_runtime(2));
fprintf('FTPA: %.4f\n', mean_runtime(3));
fprintf('MaxThroughput: %.4f\n', mean_runtime(4)); 