%-------Yalmip 调用Cplex求解IES经济调度---------%
%天然气约束函数

GasBranchIncMatrix = zeros(n_GasBus, n_GasBranch);
for i = 1: n_GasBranch
    GasBranchIncMatrix(GasBranch(i,2),i) = 1;
    GasBranchIncMatrix(GasBranch(i,3),i) = -1;
end

GasSourceIncMatrix = zeros(n_GasBus, n_GasSource);
for i = 1: n_GasSource
    GasSourceIncMatrix(GasSource(i,2),i) = 1;
end

GasGenIncMatrix = zeros(n_GasBus, n_GasGen);
for i = 1: n_GasGen
    GasGenIncMatrix(GasGen(i),i) = 1;
end

%%
%天然气平衡
for t = 1: n_T
    C = [C,
        GasSourceIncMatrix*GasSourceOutput(:,t) == GasBranchIncMatrix*GasFlow(:,t)+GasGenIncMatrix*GasGenNeed(:,t)+GasD(:,t),
        ];
end
%%
%各天然气源出力限制
for i = 1: n_GasSource
    C = [C,
        GasSource(i,3)<=GasSourceOutput(i,:)<=GasSource(i,4),
        ];
end

%%
% %各管道流量限制
% for i = 1: n_GasBranch
%     C = [C,
%         GasFlow<=GasBranch()
%         ];
% end
%%
for t=1:24
    C = [C,
        GasGenNeed(1,t) == sum(GT_G(:,t))/QLHV,
        GasGenNeed(2,t) == sum(GB_G(:,t))/QLHV,
        GasGenNeed(3,t) == -1*P2G_G(t)/10000000,
        ];
end
%% 天然气平衡
for t = 1: 24
    C = [C,
        sum(GT_G(:,t))+sum(GB_G(:,t))-P2G_G(t) == jiaohu_G(t),
        ];
end
%% 各耗气设备的耗气量限制
%燃气轮机耗气限制
for i = 1: 3
    C = [C,
        GT_G(i,:) == GT_P(i,:)/0.3,
        ];
end
%燃气锅炉耗气量限制
C = [C,
    GB_G(1,:) == GB_Q(1,:)/0.75,
    GB_G(2,:) == GB_Q(2,:)/0.88,
    ];
%P2G设备出力功率以及耗气量限制
for t=1:24
    C = [C,
        P2G_G(t) == P2G_P(t)*0.7,
        400 >= P2G_P(t) >= 0, 
        ];
end




