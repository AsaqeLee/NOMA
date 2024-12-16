% 主程序：运行NOMA系统的仿真和性能分析
% 作者：asaqe with AI   
% 日期：2024年11月18日  
%
% 更新日志：
% 2024-11-19
%   - 优化系统参数设置
%     * 调整用户数量为50
%     * 降低总功率至0.1W
%     * 提高带宽到1MHz
%     * 更新噪声功率为1e-13W
%     * 减少仿真次数至100次
%   - 添加理论上限验证
%   - 改进结果可视化
%   - 增加调试信息输出
%   - 优化性能统计方法
%
% 2024-11-18
%   - 初始版本
%   - 基本的仿真流程实现
%   - 简单的结果展示功能
%   - 基础性能统计

clc
clear
close all

% 设置中文显示
set(0,'DefaultAxesFontName','SimHei');
set(0,'DefaultTextFontName','SimHei');

% 系统参数设置
num_users = 50;           
total_power = 0.1;        % 降低总功率
bandwidth = 1e6;          % 提高带宽到1MHz
noise_power = 1e-13;      % 更现实的噪声功率
num_simulations = 100;   
max_users_per_group = 2;  % 限制每组最多2个用户

% 创建仿真实例
sim = NOMASimulation(num_users, total_power, bandwidth, noise_power, max_users_per_group);  % 更新构造函数

% 初始化结果存储
throughput_results = zeros(num_simulations, 3);  % 存储每次仿真的吞吐量
runtime_results = zeros(num_simulations, 3);     % 存储每次仿真的运行时间

% 多次仿真
for n = 1:num_simulations
    % 生成信道增益
    channel_gains = sim.generate_channel_gains();
    
    % 1. 穷尽搜索
    [groups_exhaustive, time_exhaustive] = sim.exhaustive_grouping(channel_gains);
    throughput_exhaustive = 0;
    for i = 1:length(groups_exhaustive)
        group_throughput = sim.calculate_throughput(groups_exhaustive{i}, channel_gains);
        if group_throughput > bandwidth * log2(1 + total_power/noise_power)
            warning('吞吐量超过了理论上限！');
        end
        throughput_exhaustive = throughput_exhaustive + group_throughput;
    end
    
    % 2. 随机分组
    [groups_random, time_random] = sim.random_grouping(channel_gains);
    throughput_random = 0;
    for i = 1:length(groups_random)
        if ~isempty(groups_random{i})  % 确保组不为空
            group_throughput = sim.calculate_throughput(groups_random{i}, channel_gains);
            if group_throughput > bandwidth * log2(1 + total_power/noise_power)
                warning('随机分组：吞吐量超过了理论上限！');
            end
            throughput_random = throughput_random + group_throughput;
        end
    end
    
    % 3. 匹配分组
    [groups_matching, time_matching] = sim.matching_grouping(channel_gains);
    throughput_matching = 0;
    for i = 1:length(groups_matching)
        if ~isempty(groups_matching{i})  % 确保组不为空
            group_throughput = sim.calculate_throughput(groups_matching{i}, channel_gains);
            if group_throughput > bandwidth * log2(1 + total_power/noise_power)
                warning('匹配分组：吞吐量超过了理论上限！');
            end
            throughput_matching = throughput_matching + group_throughput;
        end
    end
    
    % 存储结果
    throughput_results(n,:) = [throughput_exhaustive, throughput_random, throughput_matching];
    runtime_results(n,:) = [time_exhaustive, time_random, time_matching];

    % 在主循环中添加调试信息
    % fprintf('仿真轮次 %d:\n', n);
    % fprintf('信道增益范围: %.2e ~ %.2e\n', min(channel_gains), max(channel_gains));
    % fprintf('穷尽搜索吞吐量: %.2e\n', throughput_exhaustive);
end

% 计算平均值和标准差
mean_throughput = mean(throughput_results);
std_throughput = std(throughput_results);
mean_runtime = mean(runtime_results);

% 绘制系统吞吐量比较柱状图
figure('Renderer', 'painters');  % 使用painters渲染器
bar_data = mean_throughput;
b = bar(bar_data);
hold on;
errorbar(1:3, bar_data, std_throughput, 'k', 'LineStyle', 'none');
set(gca, 'XTickLabel', {'穷尽搜索', '随机分组', '匹配分组'});
title('系统吞吐量比较');
ylabel('平均系统吞吐量 (bps)');
grid on;

% 绘制算法运行时间比较柱状图
figure('Renderer', 'painters');  % 使用painters渲染器
bar(mean_runtime);
set(gca, 'XTickLabel', {'穷尽搜索', '随机分组', '匹配分组'});
title('算法运行时间比较');
ylabel('平均运行时间 (秒)');
grid on;

% 绘制算法收敛性分析图
figure('Renderer', 'painters');  % 使用painters渲染器
plot(1:num_simulations, throughput_results(:,1), 'r-', ...
     1:num_simulations, throughput_results(:,2), 'g--', ...
     1:num_simulations, throughput_results(:,3), 'b:');
title('算法收敛性分析');
xlabel('仿真次数');
ylabel('系统吞吐量 (bps)');
legend('穷尽搜索', '随机分组', '匹配分组', 'Location', 'best');
grid on;

% 打印统计结果
fprintf('\n====== 仿真结果统计 ======\n');
fprintf('平均系统吞吐量 (bps):\n');
fprintf('穷尽搜索: %.2e (±%.2e)\n', mean_throughput(1), std_throughput(1));
fprintf('随机分组: %.2e (±%.2e)\n', mean_throughput(2), std_throughput(2));
fprintf('匹配分组: %.2e (±%.2e)\n', mean_throughput(3), std_throughput(3));

fprintf('\n平均运行时间 (秒):\n');
fprintf('穷尽搜索: %.4f\n', mean_runtime(1));
fprintf('随机分组: %.4f\n', mean_runtime(2));
fprintf('匹配分组: %.4f\n', mean_runtime(3)); 