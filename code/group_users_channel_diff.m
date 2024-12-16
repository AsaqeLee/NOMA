function groups = group_users_channel_diff(channel_gains, num_groups)
% group_users_channel_diff 基于信道增益的用户分组
% 输入参数：
%   channel_gains - 用户信道增益向量
%   num_groups    - 用户组数
% 输出参数：
%   groups        - 单元数组，每个单元包含一组用户的索引

    num_users = length(channel_gains);
    [~, sorted_idx] = sort(channel_gains, 'descend');
    users_per_group = ceil(num_users / num_groups);
    groups = cell(1, num_groups);
    
    % 将用户按信道增益排序后分组
    for g = 1:num_groups
        start_idx = (g-1)*users_per_group + 1;
        end_idx = min(g*users_per_group, num_users);
        
        if start_idx <= num_users
            % 从强信道用户和弱信道用户中选择
            strong_users = sorted_idx(start_idx:min(start_idx+floor(users_per_group/2)-1, end_idx));
            weak_users = sorted_idx(max(end_idx-floor(users_per_group/2)+1, start_idx):end_idx);
            
            % 合并强弱用户
            groups{g} = [strong_users, weak_users];
        end
    end
end 