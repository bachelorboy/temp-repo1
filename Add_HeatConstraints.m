%-------Yalmip 调用Cplex求解IES经济调度---------%
%热网约束函数

S_pipe_F = zeros(N_Node,4);
S_pipe_T = zeros(N_Node,4);
% 设定DHN中的约束条件
C_Init_Gen_H = [];
for i = 1:N_Node
    if i ~= DataDHN.IndHs
    %这一步是在找DHN中有没有热源，若没有热源执行如下所示的操作
        C_Init_Gen_H = [C_Init_Gen_H, (Hg_HP(i,:) == 0):['Init_Gen_H_HP' num2str(i)]];
    end
end

C_H = [];
C_H = [C_H, (Hg_HP(DataDHN.IndHs,1:24) == cp*repmat(m_Hs(DataDHN.IndHs)',1,24).*...
      (tao_NS(DataDHN.IndHs,1:24) - tao_NR(DataDHN.IndHs,1:24))):'Hs']; %热源功率平衡式
C_H = [C_H, (H_Hd(DataDHN.IndHd,1:24) == cp*repmat(m_Hd(DataDHN.IndHd),1,24).*...
      (tao_NS(DataDHN.IndHd,1:24)-tao_NR(DataDHN.IndHd,1:24))):'Hd'];   %热负荷功率平衡式
for t=1:24
    C_H = [C_H, 
          Hg_HP(1,t) == (sum(GB_Q(:,t))-HS_Qin(t)+HS_Qout(t))/10000,
          Hg_HP(7,t) <= (WH_Q(t)-ORC_Q(1,t))/10000,
          ];
end
for j = 1:N_Node
    C_H = [C_H, (tao_NS_min(j) <= tao_NS(j,:) <= tao_NS_max(j)):'Tao_S_Bound']; %节点的供热温度约束
    C_H = [C_H, (tao_NR_min(j) <= tao_NR(j,:) <= tao_NR_max(j)):'Tao_R_Bound']; %节点的回热温度约束
end

C_PH = [];
for i = 1:N_Node
    temp1 = find(pipe_i == i); % 找到以节点i为起点的管道
    temp2 = find(pipe_j == i); % 找到以节点i为终点的管道
    S_pipe_F(i,1:length(temp1)) = temp1; % set of pipe with i as 'from' 
    S_pipe_T(i,1:length(temp2)) = temp2; % set of pipe with i as 'to'
end

Sum_mbR = zeros(N_Node,1); 
Sum_mbS = zeros(N_Node,1);

for i = 1:N_Node
    % 供热管道温度混合约束
     num_temp1 = size(find(S_pipe_T(i,:) == 0),2); % num. of pipe with i as 'to' 
    if num_temp1 == 0  % 这里可以理解为这个节点要供给另外最多4个节点
        b = S_pipe_T(i,1:4); % pipe incide 
        Sum_mbS(i) = sum(ms_pipe(b(1:4)));
        C_PH = [C_PH, (sum(repmat(ms_pipe(b(1:4)),1,24).*tao_PS_T(b(1:4),:))...
                == Sum_mbS(i)*tao_NS(i,:)):['Tao_Mix_S', num2str(i)]];
        C_PH = [C_PH, (tao_PR_F(b([1:4]),:) == repmat(tao_NR(i,:),4,1)):['Tao_Pipe_R_In', num2str(i)]];
    end
    if num_temp1 == 1  % 3
        b = S_pipe_T(i,1:3); % pipe indice 
        Sum_mbS(i) = sum(ms_pipe(b(1:3)));
        C_PH = [C_PH, (sum(repmat(ms_pipe(b(1:3)),1,24).*tao_PS_T(b(1:3),:))...
               == Sum_mbS(i)*tao_NS(i,:)):['Tao_Mix_S', num2str(i)]];
        C_PH = [C_PH, (tao_PR_F(b([1:3]),:) == repmat(tao_NR(i,:),3,1)):['Tao_Pipe_R_In', num2str(i)]];
    end
    if  num_temp1 == 2  % 2
        b = S_pipe_T(i,1:2); % pipe indice
        Sum_mbS(i) = sum(ms_pipe(b(1:2)));
        C_PH = [C_PH, (sum(repmat(ms_pipe(b(1:2)),1,24).*tao_PS_T(b(1:2),:))...
               == Sum_mbS(i)*tao_NS(i,:)):['Tao_Mix_S', num2str(i)]];
        C_PH = [C_PH, (tao_PR_F(b([1:2]),:) == repmat(tao_NR(i,:),2,1)):['Tao_Pipe_R_In', num2str(i)]];
    end
    if  num_temp1 == 3  % 1
        b = S_pipe_T(i,1); % pipe indice 
        Sum_mbS(i) = ms_pipe(b(1));
        C_PH = [C_PH, (ms_pipe(b(1))* tao_PS_T(b(1),:) == ms_pipe(b(1)) * tao_NS(i,:)):['Tao_Mix_S', num2str(i)]];
        C_PH = [C_PH, (tao_PR_F(b(1),:) == repmat(tao_NR(i,:),1,1)):['Tao_Pipe_R_In', num2str(i)]];
    end
    % 回水管道温度混合约束
    num_temp2 = size(find(S_pipe_F(i,:) == 0),2); % return pipe temp. mix. equation
    if num_temp2 == 0  % 4
        b = S_pipe_F(i,1:4);
        Sum_mbR(i) = sum(mr_pipe(b(1:4)));
        C_PH = [C_PH, (sum(repmat(mr_pipe(b(1:4)),1,24).*tao_PR_T(b(1:4),:))...
               == Sum_mbR(i)*tao_NR(i,:)):['Tao_Mix_R', num2str(i)]];
        C_PH = [C_PH, (tao_PS_F(b([1:4]),:) == repmat(tao_NS(i,:),4,1)):['Tao_Pipe_S_In', num2str(i)]];
    end
    if num_temp2 == 1  % 3
        b = S_pipe_F(i,1:3);
        Sum_mbR(i) = sum(mr_pipe(b(1:3)));
        C_PH = [C_PH, (sum(repmat(mr_pipe(b(1:3)),1,24).*tao_PR_T(b(1:3),:))...
               == Sum_mbR(i)*tao_NR(i,:)):['Tao_Mix_R', num2str(i)]];
        C_PH = [C_PH, (tao_PS_F(b([1:3]),:) == repmat(tao_NS(i,:),3,1)):['Tao_Pipe_S_In', num2str(i)]];
    end
    if num_temp2 == 2  % 2
        b = S_pipe_F(i,1:2);
        Sum_mbR(i) = sum(mr_pipe(b(1:2)));
        C_PH = [C_PH, (sum(repmat(mr_pipe(b(1:2)),1,24).*tao_PR_T(b(1:2),:))...
               == Sum_mbR(i)*tao_NR(i,:)):['Tao_Mix_R', num2str(i)]];
        C_PH = [C_PH, (tao_PS_F(b([1:2]),:) == repmat(tao_NS(i,:),2,1)):['Tao_Pipe_S_In', num2str(i)]];
    end
    if num_temp2 == 3  % 1
        b = S_pipe_F(i,1); 
        Sum_mbR(i) = mr_pipe(b(1));
        C_PH = [C_PH, (mr_pipe(b(1))* tao_PR_T(b(1),:) ==  Sum_mbR(i) * tao_NR(i,:)):['Tao_Mix_R', num2str(i)]];
        C_PH = [C_PH, (tao_PS_F(b(1),:) == repmat(tao_NS(i,:),1,1)):['Tao_Pipe_S_In', num2str(i)]];
    end
end

tao_am = 15; % 环境温度
tao_am = tao_am/Taob; % p.u.
tao_K = 273.15; 
tao_K = tao_K/Taob; % p.u.

for i = 1:N_Pipe  % 温度损失
    C_PH = [C_PH, tao_PS_T(i,:) - (tao_am)*ones(1,24) == (tao_PS_F(i,:) - (tao_am)*ones(1,24))*exp(-lamada_pipe(i)*L_pipe(i)/(cp*ms_pipe(i)*Mb))]; % change as psai(i) p.u. ?
    C_PH = [C_PH, tao_PR_T(i,:) - (tao_am)*ones(1,24) == (tao_PR_F(i,:) - (tao_am)*ones(1,24))*exp(-lamada_pipe(i)*L_pipe(i)/(cp*mr_pipe(i)*Mb))]; % change as psai(i) p.u.?
end
C = [C,C_H,C_PH,C_Init_Gen_H];

%%
%CSP中的弃热约束
for t = 1: 24
    C = [C,
        CSP_D(t) >= ORC_Q(2,t),
        ];
end
%%
%WH热出力
%先计算GT的热功率
for i=1:3
    for t=1:24
        C = [C,
            GT_Q(i,t) == GT_P(i,t)/0.3*0.4,
            ];
    end
end
for t = 1: 24
    C = [C,
        WH_Q(t) == 0.83*sum(GT_Q(:,t)),
        3000 >= WH_Q(t) >=0,
        ];
end
%%
%GB热出力
for t = 1: 24
    C = [C,
        1000>= GB_Q(1,t) >= 0,
        1200>= GB_Q(2,t) >= 0,
        ];
end
%%
%ORC
for t = 1: 24
    C = [C,
        ORC_P(:,t) == ORC_Q(:,t)*0.8,
        1500 >= ORC_Q(1,t) >= 0,
        800 >= ORC_Q(2,t) >= 0,
        ];
end
%%
%储热罐
%储热罐容量约束
for t=1:23
    C = [C,
        HS_S(t+1) == HS_S(t) + HS_Qin(t) - HS_Qout(t),
        ];
end
%储热罐放热、充热量以及最大容量约束
for t=1:24
    C = [C,
        800 >= HS_S(t) >= 0,
        HS_state(t)*300 >= HS_Qout(t) >= 0,
        (1-HS_state(t))*200 >= HS_Qin(t) >= 0,
        ];
end
%储热罐始末储热量平衡
C = [C,
    HS_S(24) == HS_S(1),
    HS_S(1) == 600,
    ];