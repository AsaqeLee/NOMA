% 主程序：运行NOMA系统的仿真和性能分析（6用户） 5！=120
% 作者：asaqe with AI   
% 日期：2024年11月19日  

clc
clear
close all

% 设置中文显示
set(0,'DefaultAxesFontName','SimHei');
set(0,'DefaultTextFontName','SimHei');

% 系统参数设置
num_users = 6;            % 修改为6个用户
total_power = 0.1;        % 总功率
bandwidth = 1e6;          % 带宽1MHz
noise_power = 1e-13;      % 噪声功率
num_simulations = 100;    % 仿真次数
max_users_per_group = 2;  % 每组最多2个用户

% 创建仿真实例
sim = NOMASimulation(num_users, total_power, bandwidth, noise_power, max_users_per_group);

% 初始化结果存储
throughput_results = zeros(num_simulations, 3);  % 存储每次仿真的吞吐量
runtime_results = zeros(num_simulations, 3);     % 存储每次仿真的运行时间

% 多次仿真
for n = 1:num_simulations
    fprintf('\n===== 仿真轮次 %d =====\n', n);
    
    % 生成信道增益
    channel_gains = sim.generate_channel_gains();
    
    % 1. 穷尽搜索 - 遍历所有可能的分组方式
    tic;
    max_throughput = 0;
    best_groups = {};
    
    % 生成所有可能的分组方式
    users = 1:num_users;
    all_pairs = nchoosek(users, 2);  % 所有可能的两用户组合
    num_pairs = size(all_pairs, 1);
    
    % 遍历所有可能的三组组合
    for i = 1:num_pairs
        pair1 = all_pairs(i,:);
        remaining_users = setdiff(users, pair1);
        
        % 在剩余用户中选择第二组
        remaining_pairs = nchoosek(remaining_users, 2);
        for j = 1:size(remaining_pairs, 1)
            pair2 = remaining_pairs(j,:);
            % 最后两个用户自动形成第三组
            pair3 = setdiff(remaining_users, pair2);
            
            % 计算当前分组方案的总吞吐量
            current_groups = {pair1, pair2, pair3};
            current_throughput = 0;
            
            for k = 1:length(current_groups)
                group_throughput = sim.calculate_throughput(current_groups{k}, channel_gains);
                current_throughput = current_throughput + group_throughput;
            end
            
            % 更新最优解
            if current_throughput > max_throughput
                max_throughput = current_throughput;
                best_groups = current_groups;
            end
        end
    end
    time_exhaustive = toc;
    throughput_exhaustive = max_throughput;
    
    % 打印最优分组结果
    fprintf('最优分组方案:\n');
    for i = 1:length(best_groups)
        fprintf('组%d: 用户 %d 和用户 %d\n', i, best_groups{i}(1), best_groups{i}(2));
    end
    
    % 2. 随机分组
    [groups_random, time_random] = sim.random_grouping(channel_gains);
    throughput_random = 0;
    for i = 1:length(groups_random)
        if ~isempty(groups_random{i})
            group_throughput = sim.calculate_throughput(groups_random{i}, channel_gains);
            throughput_random = throughput_random + group_throughput;
        end
    end
    
    % 3. 匹配分组
    [groups_matching, time_matching] = sim.matching_grouping(channel_gains);
    throughput_matching = 0;
    for i = 1:length(groups_matching)
        if ~isempty(groups_matching{i})
            group_throughput = sim.calculate_throughput(groups_matching{i}, channel_gains);
            throughput_matching = throughput_matching + group_throughput;
        end
    end
    
    % 存储结果
    throughput_results(n,:) = [throughput_exhaustive, throughput_random, throughput_matching];
    runtime_results(n,:) = [time_exhaustive, time_random, time_matching];
    
    % 打印当前轮次的结果
    fprintf('穷尽搜索吞吐量: %.2e\n', throughput_exhaustive);
    fprintf('随机分组吞吐量: %.2e\n', throughput_random);
    fprintf('匹配分组吞吐量: %.2e\n', throughput_matching);
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