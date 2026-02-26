%-------Yalmip 调用Cplex求解IES经济调度---------%
%设备运行成本费用

EqCost=0;
for t=1:24
    %EqCost=EqCost+0.1*PV_P(t)+0.1*WP_P(t)+0.59*sum(EC_c(:,t))+0.85*sum(GT_P(:,t))+0.15*P2G_P(t);
    EqCost=EqCost+0.1*PV_P(t)+0.1*WP_P(t)+0.15*P2G_P(t);
end
cost=cost+EqCost;