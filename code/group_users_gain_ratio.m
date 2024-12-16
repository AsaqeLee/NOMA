function groups = group_users_gain_ratio(channel_gains, num_groups)
    % 基于信道增益比的分组算法
    num_users = length(channel_gains);
    groups = cell(1, num_groups);
    
    % 计算相邻用户的信道增益比
    gain_ratios = zeros(1, num_users-1);
    for i = 1:num_users-1
        gain_ratios(i) = channel_gains(i)/channel_gains(i+1);
    end
    
    % 找到增益比最大的位置进行分组
    [~, sort_idx] = sort(gain_ratios, 'descend');
    
    % 分配用户到各组
    assigned = false(1, num_users);
    for g = 1:num_groups
        if g <= length(sort_idx)
            idx = sort_idx(g);
            if ~assigned(idx) && ~assigned(idx+1)
                groups{g} = [idx, idx+1];
                assigned([idx, idx+1]) = true;
            end
        end
    end
    
    % 处理剩余未分组的用户
    remaining = find(~assigned);
    g = 1;
    for i = 1:length(remaining)
        if g > num_groups
            g = 1;
        end
        groups{g} = [groups{g}, remaining(i)];
        g = g + 1;
    end
end 