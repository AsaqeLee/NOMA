% 修改结果存储数组大小
throughput_results = zeros(num_simulations, 3);  % 改为3种算法
fairness_results = zeros(num_simulations, 3);    
runtime_results = zeros(num_simulations, 3);     

% 删除MaxThroughput相关代码
[power_fspa, time_fspa] = pa.FSPA(channel_gains);
[power_fpa, time_fpa] = pa.FPA(channel_gains);
[power_ftpa, time_ftpa] = pa.FTPA(channel_gains);

% 修改图例和标签
set(gca, 'XTickLabel', {'FSPA', 'FPA', 'FTPA'}); 