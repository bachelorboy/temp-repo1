%-------Yalmip 调用Cplex求解IES经济调度---------%
%与气网交互费用

GasCost = 0;
% gamma_gas=[0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.25,0.25,0.25,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.25];%购气价
% for t=1:24
%     GasCost=GasCost+gamma_gas(t)*jiaohu_G(t);
% end
for t=1:24
    for i=1: n_GasSource
        GasCost=GasCost+GasSourceOutput(i,t)*GasSource(i,5);
    end
end 
cost=cost+GasCost;
