%-------Yalmip 调用Cplex求解IES经济调度---------%
%弃风光惩罚费用

AbCost=0;
for t=1:24
    AbCost=AbCost+0.4*((Pwp(t)-WP_P(t))+(Ppv(t)-PV_P(t)));
end
cost=cost+AbCost;