%-------Yalmip 调用Cplex求解IES经济调度---------%
%初始化程序

IES = feval(casename); %此时定义算例的名称为IES，并且作为class来处理
%导入各个参数
QLHV = 9.7*1000000/1000*1000;

baseMVA = IES.baseMVA;
bus = IES.bus;
branch = IES.branch;
GasBranch = IES.GasBranch;
GasBus = IES.GasBus;
GasSource = IES.GasSource;
GasGen = IES.GasGen;
n_GasBus = size(GasBus,1);
n_GasBranch = size(GasBranch,1);
n_GasSource = size(GasSource,1);
n_GasGen = size(GasGen,1);
%%
%一些常数 （似乎写成全局变量好一些，因为在其他函数里会用到）
%Bus type
PQ=1; PV=2; REF=3; NONE=4; 
%Bus
BUS_I=1; BUS_TYPE=2; BUS_PD=3; BUS_QD=4; BUS_GS=5; BUS_BS=6; 
BUS_AREA=7; BUS_VM=8; BUS_VA=9; BUS_baseKV=10; BUS_zone=11; BUS_Vmax=12; BUS_Vmin=13;
%Branch
F_BUS=1; T_BUS=2; BR_R=3; BR_X=4; BR_B=5; RATE_A=6; RATE_B=7; RATE_C=8;% standard notation (in input)
BR_RATIO=9; BR_ANGLE=10; BR_STATUS=11; BR_angmin=12; BR_angmax=13;% standard notation (in input)
BR_COEFF = 14; BR_MINDEX = 15;
%%
% --- convert bus numbering to internal bus numbering
i2e	= bus(:, BUS_I);
e2i = zeros(max(i2e), 1);
e2i(i2e) = [1:size(bus, 1)]';
bus(:, BUS_I)	= e2i( bus(:, BUS_I)	);
branch(:, F_BUS)= e2i( branch(:, F_BUS)	);
branch(:, T_BUS)= e2i( branch(:, T_BUS)	);
branch_f_bus = branch(:, F_BUS);
branch_t_bus = branch(:, T_BUS);
%%
%一些用到的数组长度
n_bus = size(bus, 1);
n_branch = size(branch, 1);

%负荷数据，按照IEEE数据中各节点负荷的比例分配
PD = bus(:, BUS_PD)/baseMVA;
% 24小时的负荷数据
P_factor = PD/sum(PD);
%P_sum = sum(PD)*IES.percent;
P_sum = EleLoad/baseMVA;
PD = P_factor*P_sum;

%天然气网负荷
% GasFactor = ones(n_GasBus,1).*(1/n_GasBus);
% GasD = GasFactor*IES.GasLoad;
GasD = zeros(6,24);
gas_zhongjian=[12.69	10.17	8.35	9.04	12	16.4	15.86	19.49	20.88	21.15	20.27	20.16	19.18	16.66	17.21	18.32	19.71	21.24	23.75	25.42	24.72	23.59	19.68	15.21]/10000;
for t=1:24
    GasD(5,t)=gas_zhongjian(t);
end
