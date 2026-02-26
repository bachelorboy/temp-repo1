%-------Yalmip 调用Cplex求解IES经济调度---------%
%冷网约束函数

S_pipe_C_F = zeros(N_Node_C,4);
S_pipe_C_T = zeros(N_Node_C,4);
% 设定DCN中的约束条件
C_Init_Gen_C = [];
for i = 1:N_Node_C
    if i ~= DataDCN.IndCs
    %这一步是在找DCN中有没有冷源，若没有冷源执行如下所示的操作
        C_Init_Gen_C = [C_Init_Gen_C, (Cg_CP(i,:) == 0):['Init_Gen_C_CP' num2str(i)]];
    end
end

C_C = [];
C_C = [C_C, (Cg_CP(DataDCN.IndCs,1:24) == cp*repmat(m_Cs(DataDCN.IndCs)',1,24).*...
      (tao_NR_C(DataDCN.IndCs,1:24) - tao_NS_C(DataDCN.IndCs,1:24))):'Cs']; %冷源功率平衡式
C_C = [C_C, (C_Cd(DataDCN.IndCd,1:24) == cp*repmat(m_Cd(DataDCN.IndCd),1,24).*...
      (tao_NR_C(DataDCN.IndCd,1:24)-tao_NS_C(DataDCN.IndCd,1:24))):'Cd'];   %冷负荷功率平衡式
for t=1:24
    C_C = [C_C, 
          Cg_CP(1,t) == (AC_c(t))/10000,
          Cg_CP(3,t) == (sum(EC_c(:,t)))/10000,
          ];
end
for j = 1:N_Node_C
    C_C = [C_C, (tao_NS_C_min(j) <= tao_NS_C(j,:) <= tao_NS_C_max(j)):'Tao_S_C_Bound']; %节点的供热温度约束
    C_C = [C_C, (tao_NR_C_min(j) <= tao_NR_C(j,:) <= tao_NR_C_max(j)):'Tao_R_C_Bound']; %节点的回热温度约束
end

C_PC = [];
for i = 1:N_Node_C
    Ctemp1 = find(pipe_C_i == i); % 找到以节点i为起点的管道
    Ctemp2 = find(pipe_C_j == i); % 找到以节点i为终点的管道
    S_pipe_C_F(i,1:length(Ctemp1)) = Ctemp1; % set of pipe with i as 'from' 
    S_pipe_C_T(i,1:length(Ctemp2)) = Ctemp2; % set of pipe with i as 'to'
end

Sum_mbR_C = zeros(N_Node_C,1); 
Sum_mbS_C = zeros(N_Node_C,1);

for i = 1:N_Node_C
    % 供热管道温度混合约束
     num_temp1_C = size(find(S_pipe_C_T(i,:) == 0),2); % num. of pipe with i as 'to' 
    if num_temp1_C == 0  % 这里可以理解为这个节点要供给另外最多4个节点
        b_C = S_pipe_C_T(i,1:4); % pipe incide 
        Sum_mbS_C(i) = sum(ms_pipe_C(b_C(1:4)));
        C_PC = [C_PC, (sum(repmat(ms_pipe_C(b_C(1:4)),1,24).*tao_PS_C_T(b_C(1:4),:))...
                == Sum_mbS_C(i)*tao_NS_C(i,:)):['Tao_Mix_C_S', num2str(i)]];
        C_PC = [C_PC, (tao_PR_C_F(b_C([1:4]),:) == repmat(tao_NR_C(i,:),4,1)):['Tao_Pipe_C_R_In', num2str(i)]];
    end
    if num_temp1_C == 1  % 3
        b_C = S_pipe_C_T(i,1:3); % pipe indice 
        Sum_mbS_C(i) = sum(ms_pipe_C(b_C(1:3)));
        C_PC = [C_PC, (sum(repmat(ms_pipe_C(b_C(1:3)),1,24).*tao_PS_C_T(b_C(1:3),:))...
               == Sum_mbS_C(i)*tao_NS_C(i,:)):['Tao_Mix_C_S', num2str(i)]];
        C_PC = [C_PC, (tao_PR_C_F(b_C([1:3]),:) == repmat(tao_NR_C(i,:),3,1)):['Tao_Pipe_C_R_In', num2str(i)]];
    end
    if  num_temp1_C == 2  % 2
        b_C = S_pipe_C_T(i,1:2); % pipe indice 
        Sum_mbS_C(i) = sum(ms_pipe_C(b_C(1:2)));
        C_PC = [C_PC, (sum(repmat(ms_pipe_C(b_C(1:2)),1,24).*tao_PS_C_T(b_C(1:2),:))...
               == Sum_mbS_C(i)*tao_NS_C(i,:)):['Tao_Mix_C_S', num2str(i)]];
        C_PC = [C_PC, (tao_PR_C_F(b_C([1:2]),:) == repmat(tao_NR_C(i,:),2,1)):['Tao_Pipe_C_R_In', num2str(i)]];
    end
    if  num_temp1_C == 3  % 1
        b_C = S_pipe_C_T(i,1:1); % pipe indice 
        Sum_mbS_C(i) = sum(ms_pipe_C(b_C(1:1)));
        C_PC = [C_PC, (sum(repmat(ms_pipe_C(b_C(1:1)),1,24).*tao_PS_C_T(b_C(1:1),:))...
               == Sum_mbS_C(i)*tao_NS_C(i,:)):['Tao_Mix_C_S', num2str(i)]];
        C_PC = [C_PC, (tao_PR_C_F(b_C([1:1]),:) == repmat(tao_NR_C(i,:),1,1)):['Tao_Pipe_C_R_In', num2str(i)]];
    end
    % 回水管道温度混合约束
    num_temp2_C = size(find(S_pipe_C_F(i,:) == 0),2); % return pipe temp. mix. equation
    if num_temp2_C == 0  % 4
        b_C = S_pipe_C_F(i,1:4);
        Sum_mbR_C(i) = sum(mr_pipe_C(b_C(1:4)));
        C_PC = [C_PC, (sum(repmat(mr_pipe_C(b_C(1:4)),1,24).*tao_PR_C_T(b_C(1:4),:))...
               == Sum_mbR_C(i)*tao_NR_C(i,:)):['Tao_Mix_C_R', num2str(i)]];
        C_PC = [C_PC, (tao_PS_C_F(b_C([1:4]),:) == repmat(tao_NS_C(i,:),4,1)):['Tao_Pipe_C_S_In', num2str(i)]];
    end
    if num_temp2_C == 1  % 3
        b_C = S_pipe_C_F(i,1:3);
        Sum_mbR_C(i) = sum(mr_pipe_C(b_C(1:3)));
        C_PC = [C_PC, (sum(repmat(mr_pipe_C(b_C(1:3)),1,24).*tao_PR_C_T(b_C(1:3),:))...
               == Sum_mbR_C(i)*tao_NR_C(i,:)):['Tao_Mix_C_R', num2str(i)]];
        C_PC = [C_PC, (tao_PS_C_F(b_C([1:3]),:) == repmat(tao_NS_C(i,:),3,1)):['Tao_Pipe_C_S_In', num2str(i)]];
    end
    if num_temp2_C == 2  % 2
        b_C = S_pipe_C_F(i,1:2);
        Sum_mbR_C(i) = sum(mr_pipe_C(b_C(1:2)));
        C_PC = [C_PC, (sum(repmat(mr_pipe_C(b_C(1:2)),1,24).*tao_PR_C_T(b_C(1:2),:))...
               == Sum_mbR_C(i)*tao_NR_C(i,:)):['Tao_Mix_C_R', num2str(i)]];
        C_PC = [C_PC, (tao_PS_C_F(b_C([1:2]),:) == repmat(tao_NS_C(i,:),2,1)):['Tao_Pipe_C_S_In', num2str(i)]];
    end
    if num_temp2_C == 3  % 1
        b_C = S_pipe_C_F(i,1); 
        Sum_mbR_C(i) = mr_pipe_C(b_C(1));
        C_PC = [C_PC, (mr_pipe_C(b_C(1))* tao_PR_C_T(b_C(1),:) ==  Sum_mbR_C(i) * tao_NR_C(i,:)):['Tao_Mix_C_R', num2str(i)]];
        C_PC = [C_PC, (tao_PS_C_F(b_C(1),:) == repmat(tao_NS_C(i,:),1,1)):['Tao_Pipe_C_S_In', num2str(i)]];
    end
end

tao_am_C = -5; % 环境温度
tao_am_C = tao_am_C/Taob; % p.u.
tao_K = 273.15; 
tao_K = tao_K/Taob; % p.u.

for i = 1:N_Pipe_C  % 温度损失
    C_PC = [C_PC, tao_PS_C_T(i,:) - (tao_am_C)*ones(1,24) == (tao_PS_C_F(i,:) - (tao_am_C)*ones(1,24))*exp(-lamada_pipe_C(i)*L_pipe_C(i)/(cp*ms_pipe_C(i)*Mb))]; % change as psai(i) p.u. ?
    C_PC = [C_PC, tao_PR_C_T(i,:) - (tao_am_C)*ones(1,24) == (tao_PR_C_F(i,:) - (tao_am_C)*ones(1,24))*exp(-lamada_pipe_C(i)*L_pipe_C(i)/(cp*mr_pipe_C(i)*Mb))]; % change as psai(i) p.u.?
end
C = [C,C_C,C_PC,C_Init_Gen_C];

%%
%EC机组约束条件
for t=1:24
    C = [C,
        200 >= EC_c(1,t) >= 0,
        400 >= EC_c(2,t) >= 0,
        EC_P(1,t) == EC_c(1,t)/3.1,
        EC_P(2,t) == EC_c(2,t)/4.2,
        ];
end

%%
%WH和GB提供的制冷热量
for t=1:24
    C = [C,
        WH_Qc(t) == WH_Q(t)/0.83*0.17,
        GB_Qc(1,t) == GB_Q(1,t)/0.75*0.25,
        GB_Qc(2,t) == GB_Q(2,t)/0.88*0.12,
        ];
end

%%
%AC机组冷出力
for t=1:24
    C = [C,
        AC_c(t) <= 1.42*(WH_Qc(t)+GB_Qc(1,t)+GB_Qc(2,t)),
        1000 >= AC_c(t) >= 0,
        ];
end