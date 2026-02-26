%-------Yalmip 调用Cplex求解IES经济调度---------%
%电功率平衡约束函数

%%
%潮流方程
% 支路潮流约束
for t = 1: 24
    C = [C,
        PF_D(:, t) == Bf*Va(:, t) + Pfinj,
        ];
end
%%
% 节点功率平衡约束(矩阵形式)
%产电机组关联矩阵
%1-7依次为 GT、外电网、ORC2、PV、WP、CSP、ORC1
GenIncMatrix = zeros(n_bus,7);
GenIncMatrix(5,1)=1;GenIncMatrix(5,2)=1;GenIncMatrix(5,3)=1;
GenIncMatrix(1,4)=1;GenIncMatrix(1,5)=1;
GenIncMatrix(4,6)=1;GenIncMatrix(4,7)=1;
%热负荷元件关联矩阵
%1-2依次为 P2G、EC
PowerConsumerIncMatrix = zeros(n_bus,2);
PowerConsumerIncMatrix(2,1)=1; %节点2负荷
PowerConsumerIncMatrix(3,2)=1; %节点3负荷
for t=1:24
    C = [C,
        PV_P(t)+WP_P(t)-PD(1,t) == Bbus(1,:)*Va(:,t)+Pbusinj(1,:),
        -1*P2G_P(t)-PD(2,t) == Bbus(2,:)*Va(:,t)+Pbusinj(2,:),
        -1*sum(EC_P(:,t))-PD(3,t) == Bbus(3,:)*Va(:,t)+Pbusinj(3,:),
        CSP_GenP(t)+ORC_P(1,t)-PD(4,t) == Bbus(4,:)*Va(:,t)+Pbusinj(4,:),
        P_buy(t)+sum(GT_P(:,t))+ORC_P(2,t)-PD(5,t)-P_sell(t) == Bbus(5,:)*Va(:,t)+Pbusinj(5,:),
        -1*PD(6,t) == Bbus(6,:)*Va(:,t)+Pbusinj(6,:),
        -1*PD(7,t) == Bbus(7,:)*Va(:,t)+Pbusinj(7,:),
        -1*PD(8,t) == Bbus(8,:)*Va(:,t)+Pbusinj(8,:),
        -1*PD(9,t) == Bbus(9,:)*Va(:,t)+Pbusinj(9,:),
        ];
end



