%========================================================================
% Yalmip求解IES最优日前经济规划
%算法主程序
%考虑了CSP余热回收、储热罐、ORC的综合代码
%测试算例为9节点电网、6节点气网、8节点热网、4节点冷网

%========================================================================
% Day-ahead Economical Dispatch of Integrated Energy System
% Copyright (C) 2020 IES Project 
%========================================================================
clc;
clear;
close all;
clear all class;

addpath('./example');
addpath('./functions');
%%选择用哪个求解器求解
ANSWER=questdlg('选择Yalmip使用的求解器:','IES系统日前规划   Powered by Denny',...
    'Cplex求解器','Gurobi求解器','Cplex求解器');

UseCplex=strcmp(ANSWER,'Cplex求解器');
UseGurobi=strcmp(ANSWER,'Gurobi求解器');

%% 算例初始化
casename = 'IES_data'; % 初始化文件
k_safe = 0.95;         % 安全系数，用于留一定的裕度，针对潮流安全约束
n_T=24;NT=24;
ColdLoad=[1076,1067,1162,1050,1043,1043,1060,1069,998,885,888,852,850,843,827,855,854,865,975,981,984,1086,1089,1081]; %系统的冷负荷需求
EleLoad=[2423,2408,2396,2411,2427,2956,3088,3506,3820,4545,4555,3573,3709,3510,3567,4141,4236,4303,4486,4204,3531,3251,2550,2504]; %系统的电负荷需求
HeatLoad=1/1000*[3762,3744,3882,3660,3464,3510,3538,3582,3200,3006,3010,3032,2830,2834,2646,2864,2836,3028,3196,3170,3168,3398,3586,3560];
HeatLoadd=[3762,3744,3882,3660,3464,3510,3538,3582,3200,3006,3010,3032,2830,2834,2646,2864,2836,3028,3196,3170,3168,3398,3586,3560];
ColdLoadd=[1076,1067,1162,1050,1043,1043,1060,1069,998,885,888,852,850,843,827,855,854,865,975,981,984,1086,1089,1081]; %系统的冷负荷需求
cp=4.2; %水的比热容，kJ/kg*℃
initial;%初始化电网和气网
SysDHN8;%初始化8节点DHN
HeatLoadCurve;%导入热负荷数据
SysDCN4;%初始化4节点DCN
ColdLoadCurve;%导入冷负荷数据
%%
%导纳矩阵计算
[Bbus, Bf, Pbusinj, Pfinj] = makeBdc(baseMVA, bus, branch);       %直流潮流
%% 创建决策变量
%---电力子系统部分----%
PF_D  = sdpvar(n_branch, n_T); % 电力系统各支路功率
Va = sdpvar(n_bus,n_T); % 电力系统各节点相角
GT_P = sdpvar(3,24,'full'); % 燃气轮机电功率出力
PV_P = sdpvar(1,24,'full'); % 光伏机组电功率出力
WP_P = sdpvar(1,24,'full'); % 风力机组电功率出力
P2G_P = sdpvar(1,24,'full'); % P2G设备耗电量
EC_P = sdpvar(2,24,'full'); % 电制冷机耗电量
ORC_P = sdpvar(2,24,'full'); % ORC电功率出力
state=binvar(1,24,'full'); % 判断是否售电，1为购电，0为卖电
CSP_D = sdpvar(1,24,'full'); % CSP的丢弃热量
CSP_S = sdpvar(1,24,'full'); % CSP中的储热罐的储热量
CSP_Qin = sdpvar(1,24,'full'); % CSP中的储热罐充热功率
CSP_Qout = sdpvar(1,24,'full'); % CSP的储热罐放热功率
CSP_SU = sdpvar(1,24,'full'); % CSP用于启动汽轮机的热量
CSP_Gen = sdpvar(1,24,'full'); % CSP的汽轮机发电所消耗的热量
CSP_GenP = sdpvar(1,24,'full'); % CSP的汽轮机发电的输出功率
CSP_u=binvar(1,24,'full'); % 判断CSP中的汽轮机是否在运行，1为运行
CSP_z=binvar(1,24,'full'); % CSP中的汽轮机的关机动作，1为关机
CSP_y=binvar(1,24,'full'); % 判断CSP中的汽轮机是否在启动状态，1为在启动状态
CSP_lambda=binvar(1,24,'full'); % 判断CSP中的储热罐状态，1为放热
P_buy = sdpvar(1,24,'full');
P_sell = sdpvar(1,24,'full');
% 天然气部分(只是拿来算耗气量与产气量的，暂未涉及气网)
GasFlow = sdpvar(n_GasBranch, n_T);         %各管道气流量
GasPressure2 = sdpvar(n_GasBus, n_T);       %各节点气压平方
GasSourceOutput = sdpvar(n_GasSource, n_T); %各天然气源节点出力
GasGenNeed = sdpvar(n_GasGen, n_T);         %各天然气发电机耗气
jiaohu_G = sdpvar(1,24,'full') % 与外气网的交互气量
GT_G = sdpvar(3,24,'full'); % 燃气轮机耗气量
P2G_G = sdpvar(1,24,'full'); % P2G设备产气量
GB_G = sdpvar(2,24,'full'); % 燃气锅炉耗气量
%-----DHN区域热力系统----%
%热网部分
tao_PS_F = sdpvar(N_Pipe,NT,'full'); % 供水管道的起始端的温度
tao_PS_T = sdpvar(N_Pipe,NT,'full'); % 供水管道的终点端的温度 
tao_PR_F = sdpvar(N_Pipe,NT,'full'); % 回水管道的起始端的温度 
tao_PR_T = sdpvar(N_Pipe,NT,'full'); % 回水管道的终点端的温度
tao_NS = sdpvar(N_Node,NT,'full');   % 节点的供热温度
tao_NR = sdpvar(N_Node,NT,'full');   % 节点的回热温度
Hg_HP = sdpvar(N_Node,24,'full'); %  DHN中的热源
%热负荷等部分
GT_Q = sdpvar(3,24,'full'); % 燃气轮机输出给WH的制热量
WH_Q = sdpvar(1,24,'full'); % 余热锅炉的产热量
GB_Q = sdpvar(2,24,'full'); % 燃气轮机的产热量
ORC_Q = sdpvar(2,24,'full'); % ORC消耗的多余热量
HS_S = sdpvar(1,24,'full'); %储热罐的储热量
HS_Qout = sdpvar(1,24,'full'); %储热罐的放热功率
HS_Qin = sdpvar(1,24,'full'); %储热罐的充热功率
HS_state = binvar(1,24,'full') % 判断储热罐状态，1为放热，0为充热
%-----DCN区域冷网系统-----%
%热网部分
tao_PS_C_F = sdpvar(N_Pipe_C,NT,'full'); % 供水管道的起始端的温度
tao_PS_C_T = sdpvar(N_Pipe_C,NT,'full'); % 供水管道的终点端的温度 
tao_PR_C_F = sdpvar(N_Pipe_C,NT,'full'); % 回水管道的起始端的温度 
tao_PR_C_T = sdpvar(N_Pipe_C,NT,'full'); % 回水管道的终点端的温度
tao_NS_C = sdpvar(N_Node_C,NT,'full');   % 节点的供热温度
tao_NR_C = sdpvar(N_Node_C,NT,'full');   % 节点的回热温度
Cg_CP = sdpvar(N_Node_C,24,'full'); %  DCN中的冷源
%冷负荷等部分
WH_Qc = sdpvar(1,24,'full'); % 余热锅炉给WH制冷所用的热量
GB_Qc = sdpvar(2,24,'full'); % 燃气轮机给WH制冷所用的热量
AC_c = sdpvar(1,24,'full'); % 吸收式制冷机的制冷量
EC_c = sdpvar(2,24,'full'); % 电制冷机的制冷量
%% 约束条件设置
C = [];     %约束条件初始
%------添加约束条件------%
%电功率平衡约束
Add_PowerFlow;
%燃气轮机、光伏、风力出力约束以及和电网交互量约束
%把P2G等元件都放到了对应的气网等部分，所以这里没涉及所由元件
Add_fadian;
%天然气约束
Add_GasConstraints;
Add_PressureStairwise;
%热网约束
Add_HeatConstraints;
%供冷约束
Add_ColdConstraints;
%% 目标函数设置
cost = 0;
%添加与电网交互费用
Add_cost_grid;
%添加与气网交互费用
Add_cost_gas;
%添加设备运行成本费用
Add_cost_eq;
%添加弃风光惩罚费用
Add_cost_ab;
%添加碳排放惩罚费用
Add_cost_w;
%% 求解器的相关配置 
if UseCplex
    ops = sdpsettings('solver','cplex','verbose',2,'usex0',0);
    ops.cplex.mip.tolerances.mipgap = 1e-6;
end
if UseGurobi
    ops = sdpsettings('solver','gurobi','verbose',2,'usex0',0);
    ops.gurobi.MIPGap = 1e-6;
    % ✅ 关键修复：TuneTimeLimit 不能是 -1，显式设成 0（禁用 tuning）
    ops.gurobi.TuneTimeLimit = 0;
end
% ops = sdpsettings('solver','cplex','verbose',2,'usex0',0,'debug',1,'savesolveroutput',1,'savesolverinput',1);
% ops.cplex.exportmodel='abc.lp';
%% 进行求解计算         
result = optimize(C, cost, ops);

if result.problem == 0 % problem =0 代表求解成功   
else
    error('求解出错');
end  

% result = optimize(C, cost, ops);
% 
% if result.problem ~= 0
%     disp('================= SOLVER FAIL =================');
%     disp(['result.problem = ', num2str(result.problem)]);
%     disp(['yalmiperror    = ', yalmiperror(result.problem)]);
%     disp('result.info:');
%     disp(result.info);
% 
%     if isfield(result,'solveroutput')
%         disp('---- solveroutput ----');
%         disp(result.solveroutput);
%     end
%     if isfield(result,'solvertime')
%         disp(['solvertime = ', num2str(result.solvertime)]);
%     end
%     error('Gurobi failed. See diagnostics above.');
% end
%%
%一些值的获取
PF_D = value(PF_D);
Va = value(Va);
GT_P = value(GT_P(:,:));
PV_P = value(PV_P(:,:));
WP_P = value(WP_P(:,:));
P2G_P = value(P2G_P(:,:));
EC_P = value(EC_P(:,:));
ORC_P = value(ORC_P(:,:));
ORC_Q = value(ORC_Q(:,:));
P_buy = value(P_buy(:,:));
P_sell = value(P_sell(:,:));
CSP_D = value(CSP_D(:,:));
CSP_S = value(CSP_S(:,:));
CSP_Qin = value(CSP_Qin(:,:));
CSP_Qout = value(CSP_Qout(:,:));
CSP_Gen = value(CSP_Gen(:,:));
CSP_GenP = value(CSP_GenP(:,:));
CSP_u=value(CSP_u(:,:));
CSP_y=value(CSP_y(:,:));
CSP_lambda=value(CSP_lambda(:,:));
tao_PS_F = 100*value(tao_PS_F(:,:));
tao_PS_T = 100*value(tao_PS_T(:,:));
tao_PR_F = 100*value(tao_PR_F(:,:));
tao_PR_T = 100*value(tao_PR_T(:,:));
tao_NS = 100*value(tao_NS(:,:));
tao_NR = 100*value(tao_NR(:,:));
WH_Q = value(WH_Q(:,:));
GB_Q = value(GB_Q(:,:));
HS_S = value(HS_S(:,:));
HS_Qout = value(HS_Qout(:,:));
HS_Qin = value(HS_Qin(:,:));
HS_state=value(HS_state(:,:));
tao_PS_C_F = 100*value(tao_PS_C_F(:,:));
tao_PS_C_T = 100*value(tao_PS_C_T(:,:));
tao_PR_C_F = 100*value(tao_PR_C_F(:,:));
tao_PR_C_T = 100*value(tao_PR_C_T(:,:));
tao_NS_C = 100*value(tao_NS_C(:,:));
tao_NR_C = 100*value(tao_NR_C(:,:));
AC_c = value(AC_c(:,:));
EC_c = value(EC_c(:,:));
GasFlow = value(GasFlow);
GasPressure = sqrt(value(GasPressure2));
GasPressure2 = value(GasPressure2);
GasSourceOutput=value(GasSourceOutput);
GasGenNeed = value(GasGenNeed);
CostGrid=value(GridCost);
CostGas=value(GasCost);
CostEq=value(EqCost);
CostAb=value(AbCost);
CostW=value(WCost);
Cost=value(cost);
display(['通过Yalmip求得的最优规划值为 : ', num2str(Cost)]);
%% 数据分析与画图
% 画图
%电网部分
for t=1:24
    Plot_EleNet(1,t)=sum(GT_P(:,t));
    Plot_EleNet(2,t)=WP_P(t);
    Plot_EleNet(3,t)=PV_P(t);
    Plot_EleNet(4,t)=CSP_GenP(t);
    Plot_EleNet(5,t)=sum(ORC_P(:,t));
    Plot_EleNet(6,t)=-1*P2G_P(t);
    Plot_EleNet(7,t)=-1*sum(EC_P(:,t));
    Plot_EleNet(8,t)=P_buy(t);
    Plot_EleNet(9,t)=-1*P_sell(t);
end
Plot_EleNet=Plot_EleNet';
figure
h=bar(Plot_EleNet,'stacked');
color=[0 0 0.75;0 1 0;1 0.5 0;0.4 0.3 0.2];
set(h(1),'FaceColor',color(1,:));
set(h(2),'FaceColor',color(2,:));
set(h(3),'FaceColor',color(3,:)); 
set(h(4),'FaceColor',color(4,:));
hold on
plot(EleLoad,'k','LineWidth',2);
xlabel('时间/h');
ylabel('功率/kW');
title('IES最优电负荷情况');
hold on
legend('GT','WP','PV','CSP','ORC','P2G','EC','购电量','售电量','电负荷');
box off
%冷负荷
for t=1:24
    Plot_ColdNet(1,t)=AC_c(t);
    Plot_ColdNet(2,t)=EC_c(1,t);
    Plot_ColdNet(3,t)=EC_c(2,t);
end
Plot_ColdNet=Plot_ColdNet';
figure
e=bar(Plot_ColdNet,'stacked');
color=[0 0 0.75;0 1 0;1 0.5 0;0.4 0.3 0.2];
set(e(1),'FaceColor',color(1,:));
set(e(2),'FaceColor',color(2,:));
set(e(3),'FaceColor',color(3,:)); 
hold on
plot(ColdLoadd,'m','LineWidth',2);
xlabel('时间/h');
ylabel('功率/kW');
title('IES最优冷负荷情况');
legend('AC','EC1','EC2','冷负荷');
box off
%热负荷
for t=1:24
    Plot_ThermNet(1,t)=sum(GB_Q(:,t));
    Plot_ThermNet(2,t)=WH_Q(t);
    Plot_ThermNet(3,t)=-1*ORC_Q(1,t);
    Plot_ThermNet(4,t)=-1*HS_Qin(t);
    Plot_ThermNet(5,t)=HS_Qout(t);
end
Plot_ThermNet=Plot_ThermNet';
figure
e_1=bar(Plot_ThermNet,'stacked');
color=[0.300956435005654,0.810590442462569,0.577780697646748;0.521721248782275,0.451274164510932,0.911313227169849;0.561880235062444,0.249969169410276,0.376220283460707;0.241554770085929,0.955437531793689,0.228764772549632;0.912720162652781,0.142650346985794,0.423524871222756;0.825734269699093,0.512563384780399,0.273596220894793;0.444545883918906,0.971925137586938,0.444565843866667;0.982062563214574,0.648320621265659,0.627515046901424;0.578267561462169,0.614671003416509,0.534641253536576;0.234423496393930,0.469650371915959,0.385442159974304];
for i=1:5
    set(e_1(i),'FaceColor',color(i,:));
end
hold on
plot(HeatLoadd,'g','LineWidth',2);
xlabel('时间/h');
ylabel('功率/kW');
title('IES最优热负荷情况');
legend('GB','WH','ORC1','HS充热','HS放热','热负荷');
box off
%CSP电站
for t=1:24
    Plot_CSP(1,t)=CSP_Qin(t);
    Plot_CSP(2,t)=-1*CSP_Qout(t);
end
Plot_CSP=Plot_CSP';
figure
e_2=bar(Plot_CSP,'stacked');
color=[0 0 0.75;0 1 0;1 0.5 0;0.4 0.3 0.2];
set(e_2(1),'FaceColor',color(1,:));
set(e_2(2),'FaceColor',color(2,:));
hold on
plot(CSP_S,'g-o','LineWidth',2);
xlabel('时间/h');
ylabel('功率/kW');
title('CSP储热罐实时情况');
legend('充热功率','放热功率','罐内热量');
box off
%热网中的节点温度
%每个节点的供给温度
x=1:24; %横坐标
figure
plot(x,tao_NS(1,:),'r-h',x,tao_NS(2,:),'m->',x,tao_NS(3,:),'c-<',x,tao_NS(4,:),'k-*',x,tao_NS(5,:),'g-^',x,tao_NS(6,:),'-.',x,tao_NS(7,:),'-v',x,tao_NS(8,:),'-p');
xlabel('时刻');
ylabel('供给温度/℃'); 
title('热网中的各个节点的供给温度');
legend('节点1','节点2','节点3','节点4','节点5','节点6','节点7','节点8');
grid on
box off
%每个节点的出口温度
figure
plot(x,tao_NR(1,:),'r-h',x,tao_NR(2,:),'c->',x,tao_NR(3,:),'m-<',x,tao_NR(4,:),'k-*',x,tao_NR(5,:),'g-^',x,tao_NR(6,:),'-.',x,tao_NR(7,:),'-v',x,tao_NR(8,:),'-p');
xlabel('时刻');
ylabel('出口温度/℃'); % 给左y轴添加轴标签
title('热网中的各个节点的出口给温度');
legend('节点1','节点2','节点3','节点4','节点5','节点6','节点7','节点8');
grid on
box off
%热网中储热罐
for t=1:24
    Plot_HS(1,t)=HS_Qin(t);
    Plot_HS(2,t)=-1*HS_Qout(t);
end
Plot_HS=Plot_HS';
figure
bar(Plot_HS,'stacked');
hold on
plot(HS_S,'g-o','LineWidth',2);
xlabel('时间/h');
ylabel('功率/kW');
title('热网中储热罐实时情况');
legend('充热功率','放热功率','罐内热量');
box off
%CSP弃热量与ORC2的关系
figure
plot(ORC_Q(2,:),'r-','LineWidth',2);
hold on
plot(CSP_D,'g-','LineWidth',2);
xlabel('时间/h');
ylabel('功率/kW');
title('CSP弃热量与ORC2的关系');
legend('ORC2吸收热量','CSP弃热量');
box off
%气网出力
for t=1:24
    Plot_GasOutput(1,t)=1000*GasSourceOutput(1,t);
    Plot_GasOutput(2,t)=1000*GasSourceOutput(2,t);
end
figure
plot(Plot_GasOutput(1,:),'r','LineWidth',2);
hold on
plot(Plot_GasOutput(2,:),'c','LineWidth',2);
xlabel('时间/h');
ylabel('出气量/km');
title('气网中的气井的出气量');
legend('气井1','气井2');
box off
%冷网中的节点温度
%每个节点的供给温度
figure
plot(x,tao_NS_C(1,:),'r-h',x,tao_NS_C(2,:),'c->',x,tao_NS_C(3,:),'m-<',x,tao_NS_C(4,:),'k-*');
xlabel('时刻');
ylabel('供给温度/℃'); 
title('冷网中的各个节点的供给温度');
legend('节点1','节点2','节点3','节点4');
grid on
box off
%每个节点的出口温度
figure
plot(x,tao_NR_C(1,:),'r-h',x,tao_NR_C(2,:),'c->',x,tao_NR_C(3,:),'m-<',x,tao_NR_C(4,:),'k-*');
xlabel('时刻');
ylabel('出口温度/℃'); % 给左y轴添加轴标签
title('冷网中各个节点的出口给温度');
legend('节点1','节点2','节点3','节点4');
grid on
box off
