% NOMASimulation.m
% 作者：asaqe with AI
% 日期：2024年11月18日
%
% 更新日志：
% 2024-11-19
%   - 改进信道模型，采用3GPP路径损耗模型
%   - 优化功率分配策略，实现分数功率分配
%   - 添加吞吐量验证机制，确保不超过理论上限
%   - 改进SIC解码顺序处理
%   - 增加调试信息输出
%   - 统一三种分组方法的评分机制
%
% 2024-11-18
%   - 初始版本
%   - 实现基本的NOMA系统仿真功能
%   - 包含三种分组方法：穷尽搜索、随机分组、匹配分组
%   - 基本的性能计算功能

classdef NOMASimulation
    properties
        N           % 用户总数
        P_total     % 系统总功率
        B           % 系统带宽
        noise       % 噪声功率
        a           % 功率分配比例
    end
    
    methods
        function obj = NOMASimulation(num_users, total_power, bandwidth, noise_power, power_ratio)
            % 构造函数：初始化系统参数
            if nargin < 5
                power_ratio = 0.7;  % 默认功率分配比例0.7
            end
            obj.N = num_users;
            obj.P_total = total_power;
            obj.B = bandwidth;
            obj.noise = noise_power;
            obj.a = power_ratio;
        end
        
        function channel_gains = generate_channel_gains(obj)
            % 修改信道增益生成方法
            % 使用更现实的路径损耗模型
            d = 10 + 90 * rand(1, obj.N);  % 用户距离基站 10-100m
            path_loss_dB = 128.1 + 37.6 * log10(d/1000);  % 3GPP路径损耗模型
            path_loss = 10.^(-path_loss_dB/10);  % 转换为线性尺度
            
            % 小尺度衰落
            rayleigh = abs(complex(randn(1,obj.N), randn(1,obj.N))).^2 / 2;
            
            % 合成信道增益
            channel_gains = path_loss .* rayleigh;
        end
        
        function [best_groups, elapsed_time] = exhaustive_grouping(obj, channel_gains)
            % 穷尽搜索法：遍历所有可能的分组方案
            tic;
            users = 1:obj.N;
            best_groups = [];
            max_score = 0;
            
            % 生成所有可能的二元组合
            combinations = nchoosek(users, 2);
            for i = 1:size(combinations, 1)
                group = combinations(i,:);
                % 计算吞吐量
                throughput = obj.calculate_throughput(group, channel_gains);
                
                % 计算用户速率
                [R1, R2] = obj.calculate_individual_rates(group, channel_gains);
                rates = [R1, R2];
                
                % 计算公平性指数
                fairness = obj.calculate_fairness(rates);
                
                % 综合评分（可以调整权重）
                w1 = 0.7;  % 吞吐量权重
                w2 = 0.3;  % 公平性权重
                score = w1 * throughput + w2 * fairness;
                
                if score > max_score
                    max_score = score;
                    best_groups = {group};
                end
            end
            elapsed_time = toc;
        end
        
        function [groups, elapsed_time] = random_grouping(obj, channel_gains)
            % 随机分组法：随机将用户分配到不同组
            tic;
            users = randperm(obj.N);
            groups = {};
            max_score = 0;
            
            % 进行多次随机尝试以获得较好的结果
            num_attempts = 10;  % 增加随机尝试次数
            
            for attempt = 1:num_attempts
                current_groups = cell(1, floor(obj.N/2));
                current_score = 0;
                
                % 每两个用户一组
                for i = 1:2:obj.N-1
                    group_idx = ceil(i/2);
                    group = users(i:i+1);
                    
                    % 计算该组的得分
                    throughput = obj.calculate_throughput(group, channel_gains);
                    [R1, R2] = obj.calculate_individual_rates(group, channel_gains);
                    fairness = obj.calculate_fairness([R1, R2]);
                    
                    % 使用与穷尽搜索相同的评分方式
                    w1 = 0.7;  % 吞吐量权重
                    w2 = 0.3;  % 公平性权重
                    score = w1 * throughput + w2 * fairness;
                    
                    current_groups{group_idx} = group;
                    current_score = current_score + score;
                end
                
                % 更新最佳分组
                if current_score > max_score
                    max_score = current_score;
                    groups = current_groups;
                end
                
                % 重新随机排列用户顺序
                users = randperm(obj.N);
            end
            elapsed_time = toc;
        end
        
        function [groups, elapsed_time] = matching_grouping(obj, channel_gains)
            % 匹配分组算法：根据信道增益进行强弱用户配对
            tic;
            [~, sorted_idx] = sort(channel_gains, 'descend');
            groups = cell(1, floor(obj.N/2));
            total_score = 0;
            
            % 强弱用户配对
            for i = 1:floor(obj.N/2)
                % 形成一组：一个信道最好的用户和一个信道最差的用户
                group = [sorted_idx(i), sorted_idx(end-i+1)];
                
                % 计算该组的得分
                throughput = obj.calculate_throughput(group, channel_gains);
                [R1, R2] = obj.calculate_individual_rates(group, channel_gains);
                fairness = obj.calculate_fairness([R1, R2]);
                
                % 使用与穷尽搜索相同的评分方式
                w1 = 0.7;  % 吞吐量权重
                w2 = 0.3;  % 公平性权重
                score = w1 * throughput + w2 * fairness;
                
                groups{i} = group;
                total_score = total_score + score;
            end
            elapsed_time = toc;
        end
        
        function throughput = calculate_throughput(obj, group, channel_gains)
            % 修改吞吐量计算方法
            power_allocation = obj.allocate_power(group, channel_gains);
            
            % 验证功率分配
            if abs(sum(power_allocation) - obj.P_total) > 1e-10
                warning('功率分配不准确，进行归一化');
                power_allocation = power_allocation / sum(power_allocation) * obj.P_total;
            end
            
            % 计算理论上限
            max_channel_gain = max(channel_gains(group));
            theoretical_limit = obj.B * log2(1 + obj.P_total * max_channel_gain / obj.noise);
            
            % 计算实际吞吐量
            throughput = 0;
            for i = 1:length(group)
                sinr = obj.calculate_sinr(group(i), group, channel_gains, power_allocation);
                user_throughput = obj.B * log2(1 + sinr);
                
                % 验证单用户吞吐量不超过理论上限
                if user_throughput > theoretical_limit
                    warning('单用户吞吐量超过理论上限，进行截断');
                    user_throughput = theoretical_limit;
                end
                
                throughput = throughput + user_throughput;
            end
            
            % 验证总吞吐量不超过系统容量
            system_capacity = obj.B * log2(1 + obj.P_total * sum(channel_gains(group)) / obj.noise);
            if throughput > system_capacity
                warning('总吞吐量超过系统容量，进行截断');
                throughput = system_capacity;
            end
        end
        
        function fairness = calculate_fairness(obj, rates)
            % 计算Jain's公平性指数
            fairness = sum(rates)^2 / (length(rates) * sum(rates.^2));
        end
        
        % 新增函数：计算个体速率
        function [R1, R2] = calculate_individual_rates(obj, group, channel_gains)
            h1 = channel_gains(group(1));
            h2 = channel_gains(group(2));
            P1 = obj.a * obj.P_total;
            P2 = (1-obj.a) * obj.P_total;
            
            % 计算SINR
            sinr1 = (P1 * h1) / (P2 * h1 + obj.noise);
            sinr2 = (P2 * h2) / obj.noise;
            
            % 计算个体速率
            R1 = obj.B * log2(1 + sinr1);
            R2 = obj.B * log2(1 + sinr2);
        end
        
        function power_allocation = allocate_power(obj, group, channel_gains)
            % 修改功率分配方法
            group_gains = channel_gains(group);
            num_users = length(group);
            power_allocation = zeros(1, num_users);
            
            % 按信道增益排序（从大到小）
            [sorted_gains, idx] = sort(group_gains, 'descend');
            
            % 使用分数功率分配策略
            total_power = obj.P_total;
            for i = 1:num_users
                if i == num_users
                    % 信道最差的用户获得剩余所有功率
                    power_allocation(idx(i)) = total_power;
                else
                    % 其他用户按比例分配
                    power = total_power * 0.25;  % 每个用户最多获得25%的剩余功率
                    power_allocation(idx(i)) = power;
                    total_power = total_power - power;
                end
            end
        end
        
        function sinr = calculate_sinr(obj, user_idx, group, channel_gains, power_allocation)
            % 计算特定用户的SINR
            h_i = channel_gains(user_idx);
            P_i = power_allocation(find(group == user_idx));
            
            % 计算干扰
            interference = 0;
            user_position = find(group == user_idx);
            
            % SIC解码顺序：信道增益大的用户先解码
            [~, decode_order] = sort(channel_gains(group), 'descend');
            current_user_decode_position = find(decode_order == user_position);
            
            % 只考虑解码顺序在当前用户之后的干扰
            for j = current_user_decode_position+1:length(group)
                interferer_idx = group(decode_order(j));
                P_j = power_allocation(find(group == interferer_idx));
                interference = interference + P_j * h_i;
            end
            
            % 计算SINR
            sinr = (P_i * h_i) / (interference + obj.noise);
        end
    end
end 