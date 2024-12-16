classdef PowerAllocation
    properties
        P_total     % 总功率
        noise       % 噪声功率
        bandwidth   % 系统带宽
        alpha = 0.6 % FTPA的衰减因子
        a = 0.3     % FPA的功率分配因子
    end
    
    methods
        function obj = PowerAllocation(total_power, noise_power, bandwidth)
            obj.P_total = total_power;
            obj.noise = noise_power;
            obj.bandwidth = bandwidth;
        end
        
        function [power_allocation, elapsed_time] = FSPA(obj, channel_gains)
            % 遍历搜索功率分配算法(FSPA)
            % 通过穷举搜索找到最优的功率分配方案
            tic;
            num_users = length(channel_gains);
            step = 0.05;  % 更细的搜索步长，提高精度
            max_throughput = 0;
            best_allocation = zeros(1, num_users);
            
            [~, idx] = sort(channel_gains, 'descend');
            power_levels = 0:step:obj.P_total;
            
            % 对于每个可能的功率分配组合
            for p = power_levels
                current_allocation = zeros(1, num_users);
                current_allocation(idx(1)) = p;  % 为第一个用户分配功率
                current_allocation(idx(2)) = obj.P_total - p;  % 剩余功率给第二个用户
                
                % 计算当前分配方案的吞吐量
                throughput = obj.calculate_group_throughput(channel_gains, current_allocation);
                
                if throughput > max_throughput
                    max_throughput = throughput;
                    best_allocation = current_allocation;
                end
            end
            
            power_allocation = best_allocation;
            elapsed_time = toc;
        end
        
        function [power_allocation, elapsed_time] = FPA(obj, channel_gains)
            % 固定功率分配算法(FPA)
            % 根据公式(7-67)实现：P_{m+1} = aP_m
            tic;
            num_users = length(channel_gains);
            [~, idx] = sort(channel_gains, 'descend');
            power_allocation = zeros(1, num_users);
            
            % 计算总的功率分配因子和
            sum_factor = 1;  % 第一个用户的因子为1
            for i = 2:num_users
                sum_factor = sum_factor + obj.a^(i-1);
            end
            
            % 从强用户到弱用户分配功率
            base_power = obj.P_total / sum_factor;
            for i = 1:num_users
                power_allocation(idx(i)) = base_power * obj.a^(i-1);
            end
            
            elapsed_time = toc;
        end
        
        function [power_allocation, elapsed_time] = FTPA(obj, channel_gains)
            % 分数功率分配算法(FTPA)
            % 根据公式(7-68)实现
            tic;
            
            % 计算信道增益与噪声比
            H = channel_gains / obj.noise;
            
            % 计算分母
            denominator = sum(H.^(-obj.alpha));
            
            % 计算每个用户的功率
            power_allocation = obj.P_total * (H.^(-obj.alpha)) / denominator;
            
            elapsed_time = toc;
        end
        
        function group_throughput = calculate_group_throughput(obj, group_gains, power_allocation)
            % 计算多用户组的总吞吐量
            [sorted_gains, idx] = sort(group_gains, 'descend');
            sorted_powers = power_allocation(idx);
            group_throughput = 0;
            
            % 计算每个用户的吞吐量（考虑SIC解码顺序）
            for i = 1:length(sorted_gains)
                % 计算干扰（只考虑未解码的信号）
                interference = 0;
                for j = i+1:length(sorted_gains)
                    interference = interference + sorted_powers(j) * sorted_gains(i);
                end
                
                % 计算SINR和速率
                sinr = (sorted_powers(i) * sorted_gains(i)) / (interference + obj.noise);
                rate = obj.bandwidth * log2(1 + sinr);
                group_throughput = group_throughput + rate;
            end
        end
        
        function rates = calculate_user_rates(obj, group_gains, power_allocation)
            % 计算组内每个用户的速率
            [sorted_gains, idx] = sort(group_gains, 'descend');
            sorted_powers = power_allocation(idx);
            rates = zeros(1, length(sorted_gains));
            
            % 按SIC解码顺序计算每个用户的速率
            for i = 1:length(sorted_gains)
                interference = 0;
                for j = i+1:length(sorted_gains)
                    interference = interference + sorted_powers(j) * sorted_gains(i);
                end
                
                sinr = (sorted_powers(i) * sorted_gains(i)) / (interference + obj.noise);
                rates(idx(i)) = obj.bandwidth * log2(1 + sinr);
            end
        end
    end
end 