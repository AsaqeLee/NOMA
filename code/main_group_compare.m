% 主程序：NOMA系统分组方案综合比较
% 作者：asaqe with AI   
% 日期：2024年11月21日  

clc
clear
close all
% 在开头添加以下代码
addpath('D:/matlab_drive/NOMA/code');  % 修改为直接添加code目录
% 设置中文显示
set(0,'DefaultAxesFontName','SimHei');
set(0,'DefaultTextFontName','SimHei');

% 系统参数设置
num_users = 6;           % 总用户数（从6开始测试）
group_size = 2;         % 每组2个用户
num_groups = ceil(num_users/group_size);  % 计算组数
total_power = 1.0;      % 每组可用总功率
bandwidth = 1e6;        % 带宽1MHz
noise_power = 1e-12;    % 噪声功率
num_simulations = 50;   % 仿真次数

% 创建功率分配实例
pa = PowerAllocation(total_power, noise_power, bandwidth);

% 初始化结果存储 - 6种分组方案
% 1.穷尽搜索 2.信道差异 3.随机 4.基于距离 5.基于增益比 6.混合分组
throughput_results = zeros(num_simulations, 6);
fairness_results = zeros(num_simulations, 6);
runtime_results = zeros(num_simulations, 6);

% 多次仿真
for n = 1:num_simulations
    fprintf('仿真进度: %d/%d\n', n, num_simulations);
    
    % 生成用户信道增益
    d = 10 + 90 * rand(1, num_users);  % 用户距离基站 10-100m
    path_loss_dB = 128.1 + 37.6 * log10(d/1000);  % 3GPP路径损耗模型
    path_loss = 10.^(-path_loss_dB/10);
    rayleigh = abs(complex(randn(1,num_users), randn(1,num_users))).^2 / 2;
    channel_gains = path_loss .* rayleigh;
    
    % 1. 穷尽搜索分组
    tic;
    groups_exhaustive = exhaustive_search_grouping(channel_gains, group_size);
    [throughput_exhaustive, fairness_exhaustive] = evaluate_grouping(groups_exhaustive, channel_gains, pa);
    time_exhaustive = toc;
    
    % 2. 信道差异分组
    tic;
    groups_channel = group_users_channel_diff(channel_gains, num_groups);
    [throughput_channel, fairness_channel] = evaluate_grouping(groups_channel, channel_gains, pa);
    time_channel = toc;
    
    % 3. 随机分组
    tic;
    groups_random = group_users_random(channel_gains, num_groups);
    [throughput_random, fairness_random] = evaluate_grouping(groups_random, channel_gains, pa);
    time_random = toc;
    
    % 4. 基于距离分组
    tic;
    groups_distance = group_users_distance(d, num_groups);
    [throughput_distance, fairness_distance] = evaluate_grouping(groups_distance, channel_gains, pa);
    time_distance = toc;
    
    % 5. 基于增益比分组
    tic;
    groups_gain_ratio = group_users_gain_ratio(channel_gains, num_groups);
    [throughput_gain_ratio, fairness_gain_ratio] = evaluate_grouping(groups_gain_ratio, channel_gains, pa);
    time_gain_ratio = toc;
    
    % 6. 混合分组策略
    tic;
    groups_hybrid = group_users_hybrid(channel_gains, d, num_groups);
    [throughput_hybrid, fairness_hybrid] = evaluate_grouping(groups_hybrid, channel_gains, pa);
    time_hybrid = toc;
    
    % 存储结果
    throughput_results(n,:) = [throughput_exhaustive, throughput_channel, throughput_random, ...
                              throughput_distance, throughput_gain_ratio, throughput_hybrid];
    fairness_results(n,:) = [fairness_exhaustive, fairness_channel, fairness_random, ...
                            fairness_distance, fairness_gain_ratio, fairness_hybrid];
    runtime_results(n,:) = [time_exhaustive, time_channel, time_random, ...
                           time_distance, time_gain_ratio, time_hybrid];
end

% 计算平均值和标准差
mean_throughput = mean(throughput_results);
std_throughput = std(throughput_results);
mean_fairness = mean(fairness_results);
std_fairness = std(fairness_results);
mean_runtime = mean(runtime_results);

% 绘制结果
methods = {'穷尽搜索', '信道差异', '随机分组', '基于距离', '增益比', '混合策略'};

% 1. 系统吞吐量比较
figure('Name', '系统吞吐量比较');
bar_data = mean_throughput;
b = bar(bar_data);
hold on;
errorbar(1:6, bar_data, std_throughput, 'k', 'LineStyle', 'none');
set(gca, 'XTickLabel', methods);
title('不同分组方案的系统吞吐量比较');
ylabel('平均系统吞吐量 (bps)');
grid on;
xtickangle(45);

% 2. 系���公平性比较
figure('Name', '系统公平性比较');
bar_data = mean_fairness;
b = bar(bar_data);
hold on;
errorbar(1:6, bar_data, std_fairness, 'k', 'LineStyle', 'none');
set(gca, 'XTickLabel', methods);
title('不同分组方案的系统公平性比较');
ylabel('平均系统公平性');
grid on;
xtickangle(45);

% 3. 算法运行时间比较
figure('Name', '算法运行时间比较');
bar(mean_runtime);
set(gca, 'XTickLabel', methods);
title('不同分组方案的运行时间比较');
ylabel('平均运行时间 (秒)');
grid on;
xtickangle(45);

% 打印统计结果
fprintf('\n====== 分组方案综合性能统计 ======\n');
fprintf('系统配置：%d个用户，每组%d个用户\n', num_users, group_size);

for i = 1:length(methods)
    fprintf('\n%s:\n', methods{i});
    fprintf('吞吐量: %.2e (±%.2e) bps\n', mean_throughput(i), std_throughput(i));
    fprintf('公平性: %.4f (±%.4f)\n', mean_fairness(i), std_fairness(i));
    fprintf('运行时间: %.4f 秒\n', mean_runtime(i));
end

% 辅助函数
function [throughput, fairness] = evaluate_grouping(groups, channel_gains, pa)
    total_throughput = 0;
    all_rates = [];
    
    for i = 1:length(groups)
        if ~isempty(groups{i})
            group_gains = channel_gains(groups{i});
            [power_allocation, ~] = pa.FTPA(group_gains);  % 使用FTPA进行功率分配
            
            % 计算该组的吞吐量和用户速率
            group_throughput = pa.calculate_group_throughput(group_gains, power_allocation);
            rates = pa.calculate_user_rates(group_gains, power_allocation);
            
            total_throughput = total_throughput + group_throughput;
            all_rates = [all_rates, rates];
        end
    end
    
    throughput = total_throughput;
    fairness = (sum(all_rates))^2 / (length(all_rates) * sum(all_rates.^2));
end 