% 主程序：NOMA系统多用户分组仿真
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
group_size = 5;          % 每组用户数
total_power = 1.0;       % 每组可用总功率
bandwidth = 1e6;         % 带宽1MHz
noise_power = 1e-12;     % 噪声功率
num_simulations = 100;   % 仿真次数

% 创建仿真实例
pa = PowerAllocation(total_power, noise_power, bandwidth);

% 初始化结果存储
num_groups = ceil(num_users/group_size);  % 计算需要的组数
throughput_results = zeros(num_simulations, 3);  % 三种分组方法的吞吐量
fairness_results = zeros(num_simulations, 3);    % 三种分组方法的公平性
runtime_results = zeros(num_simulations, 3);     % 三种分组方法的运行时间

% 多次仿真
for n = 1:num_simulations
    fprintf('仿真进度: %d/%d\n', n, num_simulations);
    
    % 生成用户信道增益
    d = 10 + 90 * rand(1, num_users);  % 用户距离基站 10-100m
    path_loss_dB = 128.1 + 37.6 * log10(d/1000);  % 3GPP路径损耗模型
    path_loss = 10.^(-path_loss_dB/10);  % 转换为线性尺度
    rayleigh = abs(complex(randn(1,num_users), randn(1,num_users))).^2 / 2;
    channel_gains = path_loss .* rayleigh;
    
    % 1. 基于信道差异的分组
    tic;
    groups_channel = group_users_channel_diff(channel_gains, num_groups);
    throughput_channel = calculate_group_performance(groups_channel, channel_gains, pa);
    time_channel = toc;
    
    % 2. 随机分组
    tic;
    groups_random = group_users_random(channel_gains, num_groups);
    throughput_random = calculate_group_performance(groups_random, channel_gains, pa);
    time_random = toc;
    
    % 3. 基于距离的分组
    tic;
    groups_distance = group_users_distance(d, num_groups);
    throughput_distance = calculate_group_performance(groups_distance, channel_gains, pa);
    time_distance = toc;
    
    % 存储结果
    throughput_results(n,:) = [throughput_channel, throughput_random, throughput_distance];
    runtime_results(n,:) = [time_channel, time_random, time_distance];
    
    % 计算系统公平性
    fairness_results(n,1) = calculate_system_fairness(groups_channel, channel_gains, pa);
    fairness_results(n,2) = calculate_system_fairness(groups_random, channel_gains, pa);
    fairness_results(n,3) = calculate_system_fairness(groups_distance, channel_gains, pa);
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
set(gca, 'XTickLabel', {'信道差异分组', '随机分组', '基于距离分组'});
title(['系统吞吐量比较 (', num2str(num_users), '用户, ', num2str(group_size), '用户/组)']);
ylabel('平均系统吞吐量 (bps)');
grid on;

% 2. 系统公平性比较
figure('Name', '系统公平性比较');
bar_data = mean_fairness;
b = bar(bar_data);
hold on;
errorbar(1:3, bar_data, std_fairness, 'k', 'LineStyle', 'none');
set(gca, 'XTickLabel', {'信道差异分组', '随机分组', '基于距离分组'});
title(['系统公平性比较 (', num2str(num_users), '用户, ', num2str(group_size), '用户/组)']);
ylabel('平均系统公平性');
grid on;

% 3. 算法运行时间比较
figure('Name', '算法运行时间比较');
bar(mean_runtime);
set(gca, 'XTickLabel', {'信道差异分组', '随机分组', '基于距离分组'});
title(['算法运行时间比较 (', num2str(num_users), '用户, ', num2str(group_size), '用户/组)']);
ylabel('平均运行时间 (秒)');
grid on;

% 打印统计结果
fprintf('\n====== 多用户分组仿真结果统计 ======\n');
fprintf('系统配置：%d个用户，每组%d个用户\n', num_users, group_size);
fprintf('\n平均系统吞吐量 (bps):\n');
fprintf('信道差异分组: %.2e (±%.2e)\n', mean_throughput(1), std_throughput(1));
fprintf('随机分组: %.2e (±%.2e)\n', mean_throughput(2), std_throughput(2));
fprintf('基于距离分组: %.2e (±%.2e)\n', mean_throughput(3), std_throughput(3));

fprintf('\n平均系统公平性:\n');
fprintf('信道差异分组: %.4f (±%.4f)\n', mean_fairness(1), std_fairness(1));
fprintf('随机分组: %.4f (±%.4f)\n', mean_fairness(2), std_fairness(2));
fprintf('基于距离分组: %.4f (±%.4f)\n', mean_fairness(3), std_fairness(3));

fprintf('\n平均运行时间 (秒):\n');
fprintf('信道差异分组: %.4f\n', mean_runtime(1));
fprintf('随机分组: %.4f\n', mean_runtime(2));
fprintf('基于距离分组: %.4f\n', mean_runtime(3));

% 辅助函数
function throughput = calculate_group_performance(groups, channel_gains, pa)
    throughput = 0;
    for i = 1:length(groups)
        if ~isempty(groups{i})
            group_gains = channel_gains(groups{i});
            % 使用FTPA进行组内功率分配
            [power_allocation, ~] = pa.FTPA(group_gains);
            % 计算该组的吞吐量
            group_throughput = pa.calculate_group_throughput(group_gains, power_allocation);
            throughput = throughput + group_throughput;
        end
    end
end

function fairness = calculate_system_fairness(groups, channel_gains, pa)
    all_rates = [];
    for i = 1:length(groups)
        if ~isempty(groups{i})
            group_gains = channel_gains(groups{i});
            [power_allocation, ~] = pa.FTPA(group_gains);
            rates = pa.calculate_user_rates(group_gains, power_allocation);
            all_rates = [all_rates, rates];
        end
    end
    fairness = (sum(all_rates))^2 / (length(all_rates) * sum(all_rates.^2));
end 