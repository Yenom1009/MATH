clc; clear; close all;

% ---------------- 简化后的数据 ----------------
% 仅保留M1导弹（取原MISSILES第一行）
M1 = [20000, 0, 2000];  % M1导弹坐标
M1_NAME = 'M1';

% 仅保留FY1无人机（取原DRONES第一行）
FY1 = [17800, 0, 1800]; % FY1无人机坐标
FY1_NAME = 'FY1';

fake_target = [0,0,0];         % 假目标点
true_target_center = [0,200,0];% 真目标圆柱下底圆心

% 真目标圆柱（半径7，高10，保持原参数）
r = 7; h = 10;
[Xc,Yc,Zc] = cylinder(r,80);   % 生成圆柱网格（80个面，更平滑）
Zc = Zc * h;                   % 缩放圆柱高度
% 平移圆柱到真目标中心位置
Xc = Xc + true_target_center(1);
Yc = Yc + true_target_center(2);
Zc = Zc + true_target_center(3);

% ---------------- 绘图（仅保留关键元素） ----------------
figure('Color','w','Position',[100 100 1400 700]);

%% 全局视图（M1、FY1、真假目标）
subplot(1,2,1); hold on; grid on; box on;

% 1. 假目标（蓝色实心球+标签）
scatter3(fake_target(1),fake_target(2),fake_target(3),120,'b','filled','o');
text(fake_target(1),fake_target(2),fake_target(3)+200,'Fake Target','Color','b','FontSize',10);

% 2. 真目标（全局视图用绿色线段简化显示，避免圆柱过小看不清）
plot3([0 0 0 0],[200 200 200 200],[0 10 10 0],'g-','LineWidth',3);
text(0,200,20,'True Target (zoom in for details)','Color','g','FontSize',10);

% 3. M1导弹（红色实心点+标签）
scatter3(M1(1),M1(2),M1(3),100,'r','filled','o');  % 增大点大小，更醒目
text(M1(1),M1(2),M1(3)+200,M1_NAME,'Color','r','FontSize',11,'FontWeight','bold');

% 4. M1指向假目标的短箭头（保留原方向逻辑，长度1000米）
dir_vec = fake_target - M1;               % M1到假目标的方向向量
dir_vec_norm = dir_vec / norm(dir_vec);   % 归一化方向（确保箭头方向准确）
arrow_end = M1 + dir_vec_norm * 1000;     % 箭头终点（从M1出发，沿方向延伸1000米）
% 绘制箭头（红色，线宽1.5，箭头大小适中）
quiver3(M1(1), M1(2), M1(3), ...
        arrow_end(1)-M1(1), arrow_end(2)-M1(2), arrow_end(3)-M1(3), ...
        0, 'Color', 'r', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);

% 5. FY1无人机（黑色实心三角形+标签）
scatter3(FY1(1),FY1(2),FY1(3),100,'k','^','filled');  % 三角形标记，区分导弹
text(FY1(1),FY1(2),FY1(3)+200,FY1_NAME,'Color','k','FontSize',11,'FontWeight','bold');

% 全局视图坐标轴与标题
xlabel('X (m)','FontSize',10); 
ylabel('Y (m)','FontSize',10); 
zlabel('Z (m)','FontSize',10);
title('Global View: M1, FY1, Fake & True Targets','FontSize',12,'FontWeight','bold');
axis equal; view(30,20);  % 保持原视角，便于观察空间关系
xlim([-1000 21000]); ylim([-1000 1000]); zlim([0 2500]);  % 缩小Y轴范围，聚焦关键元素

%% 局部视图（仅真假目标，清晰显示圆柱细节）
subplot(1,2,2); hold on; grid on; box on;

% 1. 假目标（蓝色实心球，放大显示，更清晰）
[XS,YS,ZS] = sphere(30);  % 生成球体网格（30个面）
surf(5*XS,5*YS,5*ZS,'FaceColor','b','EdgeColor','none');  % 缩放球体半径为5，突出显示
text(0,0,15,'Fake Target','Color','b','FontSize',10);

% 2. 真目标（绿色半透明圆柱，保留原平滑度）
surf(Xc,Yc,Zc,'FaceColor','g','FaceAlpha',0.4,'EdgeColor','none');  % 半透明避免遮挡
text(0,200,12,'True Target (Cylinder)','Color','g','FontSize',10);

% 局部视图坐标轴与标题
xlabel('X (m)','FontSize',10); 
ylabel('Y (m)','FontSize',10); 
zlabel('Z (m)','FontSize',10);
title('Zoomed View: Fake vs. True Target','FontSize',12,'FontWeight','bold');
axis equal; view(35,25);  % 微调视角，突出圆柱立体感
xlim([-50,50]); ylim([-50,300]); zlim([0,20]);  % 聚焦真假目标区域
camlight headlight; lighting gouraud;  % 开启光照，增强圆柱立体感