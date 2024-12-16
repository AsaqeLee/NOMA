function groups = exhaustive_search_grouping(channel_gains, group_size)
    % 穷尽搜索用户分组算法
    % 通过遍历所有可能的分组组合，找到最优的分组方案
    % 输入:
    %   channel_gains: 用户信道增益向量
    %   group_size: 每组用户数
    % 输出:
    %   groups: 分组结果，cell数组
    
    % 创建功率分配实例
    total_power = 1.0;      % 每组可用总功率
    noise_power = 1e-12;    % 噪声功率
    bandwidth = 1e6;        % 带宽1MHz
    pa = PowerAllocation(total_power, noise_power, bandwidth);
    
    num_users = length(channel_gains);
    num_groups = ceil(num_users/group_size);
    
    % 初始化默认分组方案
    groups = cell(1, num_groups);
    for g = 1:num_groups
        start_idx = (g-1)*group_size + 1;
        end_idx = min(g*group_size, num_users);
        if start_idx <= num_users
            groups{g} = start_idx:end_idx;
        else
            groups{g} = [];
        end
    end
    
    % 如果用户数小于等于组大小，直接返回一个组
    if num_users <= group_size
        groups = {1:num_users};
        return;
    end
    
    % 计算初始方案的总吞吐量
    max_throughput = calculate_total_throughput(channel_gains, groups, pa);
    best_partition = groups;
    
    % 生成所有可能的用户排列
    user_perms = perms(1:num_users);
    
    % 遍历所有可能的排列
    for i = 1:size(user_perms, 1)
        current_perm = user_perms(i,:);
        current_partition = cell(1, num_groups);
        
        % 将用户分配到各组
        for g = 1:num_groups
            start_idx = (g-1)*group_size + 1;
            end_idx = min(g*group_size, num_users);
            
            if start_idx <= num_users
                current_partition{g} = current_perm(start_idx:end_idx);
            else
                current_partition{g} = [];
            end
        end
        
        % 计算当前分组方案的总吞吐量
        current_throughput = calculate_total_throughput(channel_gains, current_partition, pa);
        
        % 更新最优解
        if current_throughput > max_throughput
            max_throughput = current_throughput;
            best_partition = current_partition;
        end
    end
    
    % 返回最优分组结果
    groups = best_partition;
end

function total_throughput = calculate_total_throughput(channel_gains, groups, pa)
    total_throughput = 0;
    for g = 1:length(groups)
        if ~isempty(groups{g})
            group_gains = channel_gains(groups{g});
            [power_allocation, ~] = pa.FTPA(group_gains);
            total_throughput = total_throughput + pa.calculate_group_throughput(group_gains, power_allocation);
        end
    end
end 