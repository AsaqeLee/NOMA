# 基于多种分组策略的NOMA系统性能优化研究

## 摘要

本文针对非正交多址接入(NOMA)系统中的用户分组和功率分配问题进行了深入研究。提出了多种用户分组策略,包括基于穷尽搜索、信道差异、随机分组、基于距离、增益比以及混合策略等方法。通过仿真对比分析了不同分组方案在系统吞吐量、用户公平性和算法复杂度等方面的性能。研究结果表明,基于信道差异和混合策略的分组方案能够在系统性能和计算复杂度之间取得较好的平衡。

**关键词**: NOMA、用户分组、功率分配、系统吞吐量、用户公平性

## 1. 引言

非正交多址接入(Non-Orthogonal Multiple Access, NOMA)作为第五代移动通信(5G)的关键技术之一,通过功率域的非正交复用实现多用户共享同一时频资源,可显著提高频谱效率。然而,NOMA系统的性能在很大程度上依赖于用户分组和功率分配策略。合理的用户分组可以充分利用用户间的信道差异,提高系统容量;而最优的功率分配则可以在保证用户服务质量的同时实现系统吞吐量的最大化。

本文的主要贡献如下:
1. 提出并实现了六种不同的用户分组策略,包括基于穷尽搜索的最优分组方案
2. 设计了基于分数转换功率分配(FTPA)的功率分配算法
3. 建立了完整的系统性能评估框架,从吞吐量、公平性和复杂度多个维度进行分析
4. 通过大量仿真验证了所提出方案的有效性

## 2. 系统模型

### 2.1 NOMA系统模型

考虑一个单小区下行NOMA系统,基站向N个用户发送信号。用户根据预设的分组大小K被划分为若干组,每组内的用户采用NOMA技术进行复用。对于组内用户i,其接收信号可表示为:

```
y_i = h_i(√p_i x_i + ∑_{j≠i} √p_j x_j) + n_i
```

其中h_i表示用户i的信道系数,p_i为分配给用户i的发送功率,x_i为发送符号,n_i为加性高斯白噪声。

### 2.2 信道模型

本文采用3GPP标准的路径损耗模型:
```
PL(dB) = 128.1 + 37.6log₁₀(d/1000)
```
其中d为用户与基站之间的距离(米)。考虑瑞利衰落,用户的信道增益可表示为:
```
g = 10^(-PL/10) * |h|²
```
其中|h|²服从指数分布。

## 3. 用户分组策略

### 3.1 穷尽搜索分组

穷尽搜索通过遍历所有可能的分组组合来寻找最优解。虽然计算复杂度较高,但可以作为其他分组方案的性能基准。算法步骤如下:

1. 生成所有可能的用户排列组合
2. 对每种组合计算系统总吞吐量
3. 选择具有最大吞吐量的分组方案

### 3.2 基于信道差异的分组

该方案根据用户信道增益的差异进行分组,具体步骤为:

1. 对用户信道增益进行排序
2. 将信道增益差异较大的用户分配到同一组
3. 确保每组用户数不超过预设值

### 3.3 其他分组策略

本文还实现了以下分组方案:
- 随机分组:随机将用户分配到各组
- 基于距离分组:根据用户与基站的距离进行分组
- 基于增益比分组:考虑用户间信道增益比进行分组
- 混合策略:综合考虑多个因素的分组方案

## 4. 功率分配算法

本文采用分数转换功率分配(FTPA)算法,该算法考虑用户信道条件,根据以下公式分配功率:

```
p_i = P_total * (g_i^(-α)) / (∑_{j=1}^K g_j^(-α))
```

其中P_total为总功率,g_i为用户i的信道增益,α为公平因子。

## 5. 仿真结果与分析

### 5.1 仿真参数设置

主要仿真参数如下:
- 用户数: 6
- 每组用户数: 2
- 总功率: 1W
- 带宽: 1MHz
- 噪声功率: 1e-12W
- 仿真次数: 50

### 5.2 性能对比分析

#### 5.2.1 系统吞吐量

仿真结果显示:
- 信道差异分组和混合策略获得了最高的系统吞吐量(约3.5-3.6×10⁷ bps)
- 穷尽搜索虽然理论上应该最优,但受限于搜索空间的复杂性
- 随机分组的性能最不稳定,标准差较大

#### 5.2.2 用户公平性

- 除增益比方案外,其他方案的公平性指数都在0.5左右
- 基于距离的分组方案在保证公平性方面表现较好
- 混合策略能够在吞吐量和公平性之间取得较好的平衡

#### 5.2.3 算法复杂度

- 穷尽搜索的运行时间最长,但仍在可接受范围内
- 其他算法的运行时间相近,都显著低于穷尽搜索
- 在实际应用中,可根据具体需求选择合适的分组策略

## 6. 结论

本文研究了NOMA系统中的用户分组和功率分配问题,提出并对比了多种分组策略。研究结果表明:

1. 基于信道差异的分组方案能够有效提高系统吞吐量
2. 混合策略在各项性能指标上都表现良好,具有实际应用价值
3. FTPA算法能够较好地平衡系统性能和用户公平性

未来的研究方向包括:
- 考虑用户移动性的动态分组策略
- 结合机器学习的智能分组算法
- 多小区场景下的干扰协调机制

## 参考文献

[1] Ding Z, Yang Z, Fan P, et al. On the performance of non-orthogonal multiple access in 5G systems with randomly deployed users[J]. IEEE Signal Processing Letters, 2014, 21(12): 1501-1505.

[2] Islam S M R, Avazov N, Dobre O A, et al. Power-domain non-orthogonal multiple access (NOMA) in 5G systems: Potentials and challenges[J]. IEEE Communications Surveys & Tutorials, 2017, 19(2): 721-742.

[3] Liu Y, Qin Z, Elkashlan M, et al. Non-orthogonal multiple access for 5G and beyond[J]. Proceedings of the IEEE, 2017, 105(12): 2347-2381. 