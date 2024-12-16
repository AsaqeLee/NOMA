classdef PowerAllocation
    properties
        P_total     % 总功率
        noise       % 噪声功率
        bandwidth   % 系统带宽
        alpha = 0.6 % FTPA的非均匀性参数
    end
    
    methods
        function obj = PowerAllocation(total_power, noise_power, bandwidth)
            obj.P_total = total_power;
            obj.noise = noise_power;
            obj.bandwidth = bandwidth;
        end
        
        function [power_allocation, elapsed_time] = FSPA(obj, channel_gains)
            % 遍历搜索功率分配法 - 更细致的搜索
            tic;
            step = 0.01;  % 更细的搜索步长
            max_throughput = 0;
            best_allocation = zeros(1, length(channel_gains));
            
            [~, idx] = sort(channel_gains, 'descend');
            
            % 限制功率分配范围，确保NOMA原则
            for a = 0.2:step:0.5  % 信道好的用户功率比例限制在20%-50%
                P1 = a * obj.P_total;
                P2 = (1-a) * obj.P_total;
                current_allocation = zeros(1, 2);
                current_allocation(idx(1)) = P1;  % 信道好的用户
                current_allocation(idx(2)) = P2;  % 信道差的用户
                
                throughput = obj.calculate_throughput(channel_gains, current_allocation);
                
                if throughput > max_throughput
                    max_throughput = throughput;
                    best_allocation = current_allocation;
                end
            end
            
            power_allocation = best_allocation;
            elapsed_time = toc;
        end
        
        function [power_allocation, elapsed_time] = FPA(obj, channel_gains)
            % 固定功率分配法 - 使用更极端的分配
            tic;
            [~, idx] = sort(channel_gains, 'descend');
            power_allocation = zeros(1, 2);
            power_allocation(idx(1)) = 0.2 * obj.P_total;  % 信道好的用户分配很少功率
            power_allocation(idx(2)) = 0.8 * obj.P_total;  % 信道差的用户分配很多功率
            elapsed_time = toc;
        end
        
        function [power_allocation, elapsed_time] = FTPA(obj, channel_gains)
            % 分数功率分配法 - 更大的alpha值
            tic;
            obj.alpha = 1.5;  % 显著增加alpha使分配更不均匀
            channel_gains_inv = channel_gains.^(-obj.alpha);
            denominator = sum(channel_gains_inv);
            power_allocation = obj.P_total * (channel_gains_inv / denominator);
            elapsed_time = toc;
        end
        
        function [power_allocation, elapsed_time] = MaxThroughput(obj, channel_gains)
            % 最大化吞吐量分配法
            tic;
            options = optimset('Display', 'off');
            
            % 定义目标函数
            objective = @(x) -obj.calculate_throughput(channel_gains, x);
            
            % 约束条件
            A = [];
            b = [];
            Aeq = [1 1];  % 功率和等于总功率
            beq = obj.P_total;
            lb = [0 0];   % 功率非负
            ub = [obj.P_total obj.P_total];
            
            % 初始猜测
            x0 = [obj.P_total/2 obj.P_total/2];
            
            % 求解优化问题
            [x, ~] = fmincon(objective, x0, A, b, Aeq, beq, lb, ub, [], options);
            
            power_allocation = x;
            elapsed_time = toc;
        end
        
        function throughput = calculate_throughput(obj, channel_gains, power_allocation)
            % 计算系统吞吐量，考虑干扰影响和理论上限
            
            % 按信道增益排序（降序）
            [sorted_gains, idx] = sort(channel_gains, 'descend');
            sorted_powers = power_allocation(idx);
            
            % 信道较好的用户（用户1）
            % 可以完全消除用户2的干扰
            sinr1 = (sorted_powers(1) * sorted_gains(1)) / obj.noise;
            R1 = obj.bandwidth * log2(1 + sinr1);
            
            % 信道较差的用户（用户2）
            % 受到用户1的强干扰
            interference = sorted_powers(1) * sorted_gains(2);
            sinr2 = (sorted_powers(2) * sorted_gains(2)) / (interference + obj.noise);
            R2 = obj.bandwidth * log2(1 + sinr2);
            
            % 计算单用户理论上限
            C1 = obj.bandwidth * log2(1 + sorted_powers(1) * sorted_gains(1) / obj.noise);
            C2 = obj.bandwidth * log2(1 + sorted_powers(2) * sorted_gains(2) / obj.noise);
            
            % 限制每个用户的速率
            R1 = min(R1, C1);
            R2 = min(R2, C2);
            
            % 总吞吐量
            throughput = R1 + R2;
        end
        
        function fairness = calculate_fairness(obj, rates)
            % 计算Jain's公平性指数
            fairness = sum(rates)^2 / (length(rates) * sum(rates.^2));
        end
    end
end 