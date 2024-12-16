function groups = group_users_hybrid(channel_gains, distances, num_groups)
    % 混合分组策略：结合信道增益和距离信息
    num_users = length(channel_gains);
    groups = cell(1, num_groups);
    
    % 归一化信道增益和距离
    norm_gains = channel_gains / max(channel_gains);
    norm_distances = distances / max(distances);
    
    % 计算综合指标
    hybrid_metric = norm_gains ./ norm_distances;
    [~, sorted_idx] = sort(hybrid_metric, 'descend');
    
    % 分组（确保每组同时包含强弱用户）
    users_per_group = ceil(num_users / num_groups);
    for g = 1:num_groups
        start_idx = (g-1)*users_per_group + 1;
        end_idx = min(g*users_per_group, num_users);
        
        if start_idx <= num_users
            group_users = sorted_idx(start_idx:end_idx);
            if length(group_users) > 1
                % 重新排序组内用户，确保信道差异
                [~, local_idx] = sort(channel_gains(group_users), 'descend');
                groups{g} = group_users(local_idx);
            else
                groups{g} = group_users;
            end
        end
    end
end 