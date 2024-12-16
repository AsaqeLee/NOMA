% 主程序：NOMA系统功率分配算法比较（多用户场景）
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
group_size = 10;          % 每组用户数
total_power = 1.0;       % 每组可用总功率
bandwidth = 1e6;         % 带宽1MHz
noise_power = 1e-12;     % 噪声功率
num_simulations = 100;   % 仿真次数

% 创建功率分配实例
pa = PowerAllocation(total_power, noise_power, bandwidth);

% 初始化结果存储
num_groups = ceil(num_users/group_size);  % 计算需要的组数
throughput_results = zeros(num_simulations, 3);  % 三种功率分配方法的吞吐量
fairness_results = zeros(num_simulations, 3);    % 三种功率分配方法的公平性
runtime_results = zeros(num_simulations, 3);     % 三种功率分配方法的运行时间

% 多次仿真
for n = 1:num_simulations
    fprintf('仿真进度: %d/%d\n', n, num_simulations);
    
    % 生成用户信道增益
    d = 10 + 90 * rand(1, num_users);  % 用户距离基站 10-100m
    path_loss_dB = 128.1 + 37.6 * log10(d/1000);  % 3GPP路径损耗模型
    path_loss = 10.^(-path_loss_dB/10);  % 转换为线性尺度
    rayleigh = abs(complex(randn(1,num_users), randn(1,num_users))).^2 / 2;
    channel_gains = path_loss .* rayleigh;
    
    % 使用信道差异分组方法
    groups = group_users_channel_diff(channel_gains, num_groups);
    
    % 对每种功率分配方法进行测试
    % 1. FSPA
    tic;
    [throughput_fspa, fairness_fspa] = evaluate_power_allocation(groups, channel_gains, pa, 'FSPA');
    time_fspa = toc;
    
    % 2. FPA
    tic;
    [throughput_fpa, fairness_fpa] = evaluate_power_allocation(groups, channel_gains, pa, 'FPA');
    time_fpa = toc;
    
    % 3. FTPA
    tic;
    [throughput_ftpa, fairness_ftpa] = evaluate_power_allocation(groups, channel_gains, pa, 'FTPA');
    time_ftpa = toc;
    
    % 存储结果
    throughput_results(n,:) = [throughput_fspa, throughput_fpa, throughput_ftpa];
    fairness_results(n,:) = [fairness_fspa, fairness_fpa, fairness_ftpa];
    runtime_results(n,:) = [time_fspa, time_fpa, time_ftpa];
end

% 计算平均值和标准差
mean_throughput = mean(throughput_results);
std_throughput = std(throughput_results);
mean_fairness = mean(fairness_results);
std_fairness = std(fairness_results);
mean_runtime = mean(runtime_results);

% 绘制结果
% 1. 系统吞吐量比较
figure('Name', '系统吞吐量比较');
bar_data = mean_throughput;
b = bar(bar_data);
hold on;
errorbar(1:3, bar_data, std_throughput, 'k', 'LineStyle', 'none');
set(gca, 'XTickLabel', {'FSPA', 'FPA', 'FTPA'});
title(['功率分配算法吞吐量比较 (', num2str(num_users), '用户, ', num2str(group_size), '用户/组)']);
ylabel('平均系统吞吐量 (bps)');
grid on;

% 2. 系统公平性比较
figure('Name', '系统公平性比较');
bar_data = mean_fairness;
b = bar(bar_data);
hold on;
errorbar(1:3, bar_data, std_fairness, 'k', 'LineStyle', 'none');
set(gca, 'XTickLabel', {'FSPA', 'FPA', 'FTPA'});
title(['功率分配算法公平性比较 (', num2str(num_users), '用户, ', num2str(group_size), '用户/组)']);
ylabel('平均系统公平性');
grid on;

% 3. 算法运行时间比较
figure('Name', '算法运行时间比较');
bar(mean_runtime);
set(gca, 'XTickLabel', {'FSPA', 'FPA', 'FTPA'});
title(['功率分配算法运行时间比较 (', num2str(num_users), '用户, ', num2str(group_size), '用户/组)']);
ylabel('平均运行时间 (秒)');
grid on;

% 4. 吞吐量-公平性权衡图
figure('Name', '吞吐量-公平性权衡');
scatter(throughput_results(:,1), fairness_results(:,1), 'r', 'DisplayName', 'FSPA');
hold on;
scatter(throughput_results(:,2), fairness_results(:,2), 'g', 'DisplayName', 'FPA');
scatter(throughput_results(:,3), fairness_results(:,3), 'b', 'DisplayName', 'FTPA');
xlabel('系统吞吐量 (bps)');
ylabel('系统公平性');
title('吞吐量-公平性权衡分析');
legend('Location', 'best');
grid on;

% 打印统计结果
fprintf('\n====== 功率分配算法性能统计 ======\n');
fprintf('系统配置：%d个用户，每组%d个用户\n', num_users, group_size);
fprintf('\n平均系统吞吐量 (bps):\n');
fprintf('FSPA: %.2e (±%.2e)\n', mean_throughput(1), std_throughput(1));
fprintf('FPA: %.2e (±%.2e)\n', mean_throughput(2), std_throughput(2));
fprintf('FTPA: %.2e (±%.2e)\n', mean_throughput(3), std_throughput(3));

fprintf('\n平均系统公平性:\n');
fprintf('FSPA: %.4f (±%.4f)\n', mean_fairness(1), std_fairness(1));
fprintf('FPA: %.4f (±%.4f)\n', mean_fairness(2), std_fairness(2));
fprintf('FTPA: %.4f (±%.4f)\n', mean_fairness(3), std_fairness(3));

fprintf('\n平均运行时间 (秒):\n');
fprintf('FSPA: %.4f\n', mean_runtime(1));
fprintf('FPA: %.4f\n', mean_runtime(2));
fprintf('FTPA: %.4f\n', mean_runtime(3));

% 辅助函数
function [total_throughput, system_fairness] = evaluate_power_allocation(groups, channel_gains, pa, method)
    total_throughput = 0;
    all_rates = [];
    
    % 对每个组进���功率分配和性能计算
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
    
    % 计算系统公平性
    system_fairness = (sum(all_rates))^2 / (length(all_rates) * sum(all_rates.^2));
end 