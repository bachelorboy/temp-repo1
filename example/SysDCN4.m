% Sb = 10; % MW
% Taob = 100; % K
% % Mb = Sb/cp/Taob;% 100/4.2 = 23.8 Kg/s
% Mb = 23.8;
% m_adj_factor = 2;
% DCN中的管道数据
% No.(1)|From(2)|To(3)|L(4)m|u_T(5)|u_p(6)|ms(7)|diameter(8)
pipe_C = [
    1	1	2	60  	0.321	0.4   4	    18
    2	3	2	40   	0.21	0.4	  3	    12
    3	2	4	80      0.21	0.4	  7	    18
];
N_Pipe_C = size(pipe_C,1); % 计算管道数量
pipe_C_i = pipe_C(:,2); % 管道从哪个节点流出
pipe_C_j = pipe_C(:,3); % 管道从哪个节点流入
L_pipe_C = pipe_C(:,4); % 管道长度
lamada_pipe_C= pipe_C(:,5)/1e3/10/10; % 计算管道的热传导系数
miu_pipe_C = pipe_C(:,6); %不知道这个是个啥
ms_pipe_C = pipe_C(:,7)/m_adj_factor; % 供热管道流量
mr_pipe_C = pipe_C(:,7)/m_adj_factor; % 回热管道流量
ms_pipe_C = ms_pipe_C/Mb; % p.u.   计算对应的标幺值
mr_pipe_C = mr_pipe_C/Mb; % p.u.

psai_C = zeros(N_Pipe_C,1); % 管道的温度损失系数
psai_C = exp(-lamada_pipe_C.*L_pipe_C./(cp*ms_pipe_C)); % p.u. 计算温损(标幺值下)
psaiR_C = psai_C; %回热管道的温损系数
psaiS_C = psai_C; %供热管道的温损系数

% Heat Node
%  No(1)|Hd(2)|tao_S_max(3)|tao_S_min(4)|tao_R_max(5)|
%        tao_R_min(6)|mass flow(7)
coldnode = [ %MW      %℃  % 
    % Assumed that there is no heat load at the interconnected point
    1	0       10	0	25	10  4    % source
    2	0       10	0	25	10  0
    3	0    	10	0	25	10  3    % source
    4	1    	10	0	25	10  7    % load
];

coldnode(:,7) = coldnode(:,7); % p.u.
pipe_C(:,7) = pipe_C(:,7); % p.u.

N_Node_C = length(coldnode(:,1)); %存储DHN中的热力节点编号
coldnode(:,2) = coldnode(:,2)/Sb; % p.u.
Nd_Cd = find(coldnode(:,2)>0); % load
Nd_Cs = [1 3]; % adjust
N_Node_C = size(coldnode,1);
m_Cs = zeros(1,N_Node_C); % source
m_Cs(Nd_Cs) = coldnode(Nd_Cs,7)/m_adj_factor;
m_Cs = m_Cs/Mb; % p.u.
m_Cd = coldnode(:,7)/m_adj_factor;% load
m_Cd(Nd_Cs) = 0; % 
m_Cd = m_Cd/Mb; % p.u.
C_ratio = coldnode(:,2)/sum(coldnode(:,2)); 
%这里存储节点的最大/最小的供/回热温度，注意这里都是摄氏温度的
tao_NS_C_max = coldnode(:,3); % K
tao_NS_C_min = coldnode(:,4);
tao_NR_C_max = coldnode(:,5);
tao_NR_C_min = coldnode(:,6);
%把温度都化成100摄氏度的标幺值
tao_NS_C_max = tao_NS_C_max/Taob; % p.u.
tao_NS_C_min = tao_NS_C_min/Taob; % p.u. 
tao_NR_C_max = tao_NR_C_max/Taob; % p.u.
tao_NR_C_min = tao_NR_C_min/Taob; % p.u.

% 定义Structure
DataDCN.IndCd = Nd_Cd;
DataDCN.IndCs = Nd_Cs;