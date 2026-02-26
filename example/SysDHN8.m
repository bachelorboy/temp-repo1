Sb = 10; % MW
Taob = 100; % K
% Mb = Sb/cp/Taob;% 100/4.2 = 23.8 Kg/s
Mb = 23.8;
m_adj_factor = 2;
% DHN中的管道数据
% No.(1)|From(2)|To(3)|L(4)m|u_T(5)|u_p(6)|ms(7)|diameter(8)
pipe = [
    1	1	2	257.6	0.321	0.4   6	    125
    2	2	5	97.5	0.21	0.4	  2	    40
    3	2	3	51      0.21	0.4	  4	    40
    4	3	6	59.5	0.327	0.4	  2	    100
    5	3	4	271.3	0.189	0.4	  2	    32
    6	4	8	235.4	0.236	0.4	  6	    65 
    7	7	4	177.3	0.21	0.4	  4   	40
];
N_Pipe = size(pipe,1); % 计算管道数量
pipe_i = pipe(:,2); % 管道从哪个节点流出
pipe_j = pipe(:,3); % 管道从哪个节点流入
L_pipe = pipe(:,4); % 管道长度
lamada_pipe = pipe(:,5)/1e3/10/10; % 计算管道的热传导系数
miu_pipe = pipe(:,6); %不知道这个是个啥
ms_pipe = pipe(:,7)/m_adj_factor; % 供热管道流量
mr_pipe = pipe(:,7)/m_adj_factor; % 回热管道流量
ms_pipe = ms_pipe/Mb; % p.u.   计算对应的标幺值
mr_pipe = mr_pipe/Mb; % p.u.

psai = zeros(N_Pipe,1); % 管道的温度损失系数
psai = exp(-lamada_pipe.*L_pipe./(cp*ms_pipe)); % p.u. 计算温损(标幺值下)
psaiR = psai; %回热管道的温损系数
psaiS = psai; %供热管道的温损系数

% Heat Node
%  No(1)|Hd(2)|tao_S_max(3)|tao_S_min(4)|tao_R_max(5)|
%        tao_R_min(6)|mass flow(7)
heatnode = [ %MW      %℃  % 
    % Assumed that there is no heat load at the interconnected point
    1	0       100	70	70	15  6    % source
    2	0       100	70	70	15  0
    3	0    	100	70	70	15  0 
    4	0    	100	70	70	15  0 
    5	0.30    100	70	70	15  2    % load
    6	0.30	100	70	70	15  2    % load
    7	0   	100	70	70	15  4    % source
    8	0.40	100	70	70	15  6    % load
];

heatnode(:,7) = heatnode(:,7)*3; % p.u.
pipe(:,7) = pipe(:,7)*3; % p.u.

N_Node = length(heatnode(:,1)); %存储DHN中的热力节点编号
heatnode(:,2) = heatnode(:,2)/Sb; % p.u.
Nd_Hd = find(heatnode(:,2)>0); % load
Nd_Hs = [1 7]; % adjust
N_Node = size(heatnode,1);
m_Hs = zeros(1,N_Node); % source
m_Hs(Nd_Hs) = heatnode(Nd_Hs,7)/m_adj_factor;
m_Hs = m_Hs/Mb; % p.u.
m_Hd = heatnode(:,7)/m_adj_factor;% load
m_Hd(Nd_Hs) = 0; % 
m_Hd = m_Hd/Mb; % p.u.
H_ratio = heatnode(:,2)/sum(heatnode(:,2)); 
%这里存储节点的最大/最小的供/回热温度，注意这里都是摄氏温度的
tao_NS_max = heatnode(:,3); % K
tao_NS_min = heatnode(:,4);
tao_NR_max = heatnode(:,5);
tao_NR_min = heatnode(:,6);
%把温度都化成100摄氏度的标幺值
tao_NS_max = tao_NS_max/Taob; % p.u.
tao_NS_min = tao_NS_min/Taob; % p.u. 
tao_NR_max = tao_NR_max/Taob; % p.u.
tao_NR_min = tao_NR_min/Taob; % p.u.

% 定义Structure
DataDHN.IndHd = Nd_Hd;
DataDHN.IndHs = Nd_Hs;