function groups = group_users_distance(distances, num_groups)
% group_users_distance 基于距离的用户分组
% 输入参数：
%   distances  - 用户到基站的距离向量
%   num_groups - 用户组数
% 输出参数：
%   groups     - 单元数组，每个单元包含一组用户的索引

    num_users = length(distances);
    [~, sorted_idx] = sort(distances);  % 按距离升序排序
    users_per_group = ceil(num_users / num_groups);
    groups = cell(1, num_groups);
    
    % 将用户按距离排序后分组
    for g = 1:num_groups
        start_idx = (g-1)*users_per_group + 1;
        end_idx = min(g*users_per_group, num_users);
        
        if start_idx <= num_users
            % 从近距离用户和远距离用户中选择
            near_users = sorted_idx(start_idx:min(start_idx+floor(users_per_group/2)-1, end_idx));
            far_users = sorted_idx(max(end_idx-floor(users_per_group/2)+1, start_idx):end_idx);
            
            % 合并近远用户
            groups{g} = [near_users, far_users];
        end
    end
end 