function groups = group_users_random(channel_gains, num_groups)
% group_users_random 随机用户分组
% 输入参数：
%   channel_gains - 用户信道增益向量
%   num_groups    - 用户组数
% 输出参数：
%   groups        - 单元数组，每个单元包含一组用户的索引

    num_users = length(channel_gains);
    users_per_group = ceil(num_users / num_groups);
    groups = cell(1, num_groups);
    
    % 随机打乱用户顺序
    shuffled_users = randperm(num_users);
    
    % 将用户随机分配到各组
    for g = 1:num_groups
        start_idx = (g-1)*users_per_group + 1;
        end_idx = min(g*users_per_group, num_users);
        
        if start_idx <= num_users
            groups{g} = shuffled_users(start_idx:end_idx);
        end
    end
end 