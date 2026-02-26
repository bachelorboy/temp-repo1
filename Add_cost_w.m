%-------Yalmip 调用Cplex求解IES经济调度---------%
%碳排放惩罚费用

WCost=0;
for t=1:24
    R_w(t)=0.55*sum(GT_P(:,t))+0.35*sum(GB_Q(:,t))+0.45*P_buy(t)-0.7*P2G_P(t);
    WCost=WCost+0.21*R_w(t);
end
cost=cost+WCost;