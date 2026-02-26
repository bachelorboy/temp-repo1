%-------Yalmip 调用Cplex求解IES经济调度---------%
%燃气轮机、光伏、风力出力以及和电网交互量约束

%燃气轮机发电出力约束
GT_max=[1500,2000,2500];
GT_min=[15,20,25];
for  t = 1: 24
    for i = 1: 3
        C = [C,
            GT_max(i) >= GT_P(i,t) >= GT_min(i),
            ];
    end
end
%光伏风力机组电出力约束
Pwp=5*[32,33,38,45,54,23,45,34,56,76,32,34,12,45,67,32,45,65,43,21,34,11,23,45]; %风力预测出力
Ppv=5*[0,0,0,0,0,30,60,82,90,97,120,135,135,130,110,72,63,0,0,0,0,0,0,0]; %光伏预测出
for  t = 1: 24
    C = [C,
        Ppv(t) >= PV_P(t) >= 0,
        Pwp(t) >= WP_P(t) >= 0,
        ];
end
%与电网交互电量约束
for  t = 1: 24
    C = [C,
        state(t)*1500 >= P_buy(t) >= 0,
        (1-state(t))*1000 >= P_sell(t) >= 0,
        ];
end

%%
%CSP约束条件
%热量传递约束
Qsf=2*Ppv;
for t=1:24
    C = [C,
        Qsf(t) == CSP_D(t)+CSP_Qin(t)-CSP_Qout(t)+CSP_SU(t)+CSP_Gen(t),
        CSP_D(t) >= 0,
        217*CSP_lambda(t) >= CSP_Qout(t) >= 0,
        304*(1-CSP_lambda(t)) >= CSP_Qin(t) >= 0,
        1736 >= CSP_S(t) >= 0,
        ];
end
%CSP中的储热罐始末储热量平衡
C = [C,
    CSP_S(24) == CSP_S(1),
    CSP_S(1) == 819,
    ];
%CSP中的储热罐容量约束
for t=1:23
    C = [C,
        CSP_S(t+1) == CSP_S(t) + CSP_Qin(t)*0.98 - CSP_Qout(t)/0.98,
        ];
end
%CSP中的汽轮机启动约束
%Part1 热量约束
for t=1:24
    C = [C,
        CSP_y(t)*217 >= CSP_SU(t),
        88 >= CSP_SU(t) >= CSP_y(t)*88,
        (CSP_y(t)+CSP_u(t))*217 >= CSP_SU(t)+ CSP_Gen(t),
        217 >= CSP_Gen(t) >= 0,
        ];
end
%Part2 0-1变量约束
%初始状态
C = [C,
    CSP_u(1) == 1,
    ];
for t=2:24
    C = [C,
        CSP_u(t)-CSP_u(t-1) == CSP_y(t-1)-CSP_z(t),
        1 >= CSP_y(t-1)+CSP_z(t) >= 0,
        ];
end
%CSP的汽轮机发电输出功率
for t=1:24
    C = [C,
        CSP_GenP(t) == 0.4819*CSP_Gen(t),
        ];
end