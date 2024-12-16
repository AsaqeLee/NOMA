% 主程序：NOMA系统不同组大小下的功率分配算法比较
% 作者：asaqe with AI   
% 日期：2024年11月21日  

clc
clear
close all

% 设置中文显示
set(0,'DefaultAxesFontName','SimHei');
set(0,'DefaultTextFontName','SimHei');

% 系统参数设置
num_users = 50;           % 总用户数
group_sizes = 2:2:10;    % 研究的组大小范围
total_power = 1.0;       % 每组可用总功率
bandwidth = 1e6;         % 带宽1MHz
noise_power = 1e-12;     % 噪声功率
num_simulations = 50;    % 每个组大小的仿真次数

% 创建功率分配实例
pa = PowerAllocation(total_power, noise_power, bandwidth);

% 初始化结果存储
num_group_sizes = length(group_sizes);
mean_throughput = zeros(num_group_sizes, 3);  % [FSPA, FPA, FTPA]
mean_fairness = zeros(num_group_sizes, 3);
mean_runtime = zeros(num_group_sizes, 3);
std_throughput = zeros(num_group_sizes, 3);
std_fairness = zeros(num_group_sizes, 3);

% 对每个组大小进行仿真
for g = 1:num_group_sizes
    group_size = group_sizes(g);
    num_groups = ceil(num_users/group_size);
    
    % 临时存储当前组大小的结果
    throughput_results = zeros(num_simulations, 3);
    fairness_results = zeros(num_simulations, 3);
    runtime_results = zeros(num_simulations, 3);
    
    fprintf('正在仿真组大小 %d 的情况...\n', group_size);
    
    % 多次仿真
    for n = 1:num_simulations
        % 生成用户信道增益
        d = 10 + 90 * rand(1, num_users);  % 用户距离基站 10-100m
        path_loss_dB = 128.1 + 37.6 * log10(d/1000);  % 3GPP路径损耗模型
        path_loss = 10.^(-path_loss_dB/10);
        rayleigh = abs(complex(randn(1,num_users), randn(1,num_users))).^2 / 2;
        channel_gains = path_loss .* rayleigh;
        
        % 使用信道差异分组方法
        groups = group_users_channel_diff(channel_gains, num_groups);
        
        % 测试三种功率分配方法
        [throughput_fspa, fairness_fspa, time_fspa] = evaluate_power_allocation(groups, channel_gains, pa, 'FSPA');
        [throughput_fpa, fairness_fpa, time_fpa] = evaluate_power_allocation(groups, channel_gains, pa, 'FPA');
        [throughput_ftpa, fairness_ftpa, time_ftpa] = evaluate_power_allocation(groups, channel_gains, pa, 'FTPA');
        
        % 存储结果
        throughput_results(n,:) = [throughput_fspa, throughput_fpa, throughput_ftpa];
        fairness_results(n,:) = [fairness_fspa, fairness_fpa, fairness_ftpa];
        runtime_results(n,:) = [time_fspa, time_fpa, time_ftpa];
    end
    
    % 计算平均值和标准差
    mean_throughput(g,:) = mean(throughput_results);
    mean_fairness(g,:) = mean(fairness_results);
    mean_runtime(g,:) = mean(runtime_results);
    std_throughput(g,:) = std(throughput_results);
    std_fairness(g,:) = std(fairness_results);
end

% 绘制结果
% 1. 不同组大小下的系统吞吐量比较
figure('Name', '不同组大小下的系统吞吐量比较');
plot(group_sizes, mean_throughput(:,1), 'r-o', 'DisplayName', 'FSPA');
hold on;
plot(group_sizes, mean_throughput(:,2), 'g-s', 'DisplayName', 'FPA');
plot(group_sizes, mean_throughput(:,3), 'b-d', 'DisplayName', 'FTPA');
xlabel('组大小');
ylabel('平均系统吞吐量 (bps)');
title('不同组大小下的系统吞吐量比较');
legend('Location', 'best');
grid on;

% 2. 不同组大小下的系统公平性比较
figure('Name', '不同组大小下的系统公平性比较');
plot(group_sizes, mean_fairness(:,1), 'r-o', 'DisplayName', 'FSPA');
hold on;
plot(group_sizes, mean_fairness(:,2), 'g-s', 'DisplayName', 'FPA');
plot(group_sizes, mean_fairness(:,3), 'b-d', 'DisplayName', 'FTPA');
xlabel('组大小');
ylabel('平均系统公平性');
title('不同组大小下的系统公平性比较');
legend('Location', 'best');
grid on;

% 3. 不同组大小下的算法运行时间比较
figure('Name', '不同组大小下的算法运行时间比较');
plot(group_sizes, mean_runtime(:,1), 'r-o', 'DisplayName', 'FSPA');
hold on;
plot(group_sizes, mean_runtime(:,2), 'g-s', 'DisplayName', 'FPA');
plot(group_sizes, mean_runtime(:,3), 'b-d', 'DisplayName', 'FTPA');
xlabel('组大小');
ylabel('平均运行时间 (秒)');
title('不同组大小下的算法运行时间比较');
legend('Location', 'best');
grid on;

% 打印详细结果
fprintf('\n====== 不同组大小下的性能统计 ======\n');
for g = 1:num_group_sizes
    fprintf('\n组大小: %d\n', group_sizes(g));
    fprintf('平均系统吞吐量 (bps):\n');
    fprintf('FSPA: %.2e (±%.2e)\n', mean_throughput(g,1), std_throughput(g,1));
    fprintf('FPA: %.2e (±%.2e)\n', mean_throughput(g,2), std_throughput(g,2));
    fprintf('FTPA: %.2e (±%.2e)\n', mean_throughput(g,3), std_throughput(g,3));
    
    fprintf('\n平均系统公平性:\n');
    fprintf('FSPA: %.4f (±%.4f)\n', mean_fairness(g,1), std_fairness(g,1));
    fprintf('FPA: %.4f (±%.4f)\n', mean_fairness(g,2), std_fairness(g,2));
    fprintf('FTPA: %.4f (±%.4f)\n', mean_fairness(g,3), std_fairness(g,3));
    
    fprintf('\n平均运行时间 (秒):\n');
    fprintf('FSPA: %.4f\n', mean_runtime(g,1));
    fprintf('FPA: %.4f\n', mean_runtime(g,2));
    fprintf('FTPA: %.4f\n', mean_runtime(g,3));
end

% 辅助函数
function [throughput, fairness, time] = evaluate_power_allocation(groups, channel_gains, pa, method)
    tic;
    total_throughput = 0;
    all_rates = [];
    
    % 对每个组进行功率分配和性能计算
    for i = 1:length(groups)
        if ~isempty(groups{i})
            group_gains = channel_gains(groups{i});
            
            % 根据指定方法进行功率分配
            switch method
                case 'FSPA'
                    [power_allocation, ~] = pa.FSPA(group_gains);
                case 'FPA'
                    [power_allocation, ~] = pa.FPA(group_gains);
                case 'FTPA'
                    [power_allocation, ~] = pa.FTPA(group_gains);
            end
            
            % 计算该组的吞吐量和用户速率
            group_throughput = pa.calculate_group_throughput(group_gains, power_allocation);
            rates = pa.calculate_user_rates(group_gains, power_allocation);
            
            total_throughput = total_throughput + group_throughput;
            all_rates = [all_rates, rates];
        end
    end
    
    time = toc;
    throughput = total_throughput;
    fairness = (sum(all_rates))^2 / (length(all_rates) * sum(all_rates.^2));
end 