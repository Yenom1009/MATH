clc; clear; close all;

% ---------------- 基础数据与运动参数 ----------------
% 1. 初始位置（仅用于计算最终位置，不显示）
M1_init = [20000, 0, 2000];       % M1初始坐标
FY1_init = [17800, 0, 1800];      % FY1初始坐标
fake_target = [0, 0, 0];          % 假目标（固定显示）
true_target_center = [0, 200, 0]; % 真目标圆柱中心（固定显示）

% 2. 运动参数（用于计算最终位置）
t = 1.5;                          % 运动时间
v_M1 = 300;                       % M1速度（指向假目标）
v_FY1 = 120;                      % FY1速度（垂直z轴向z轴靠近）

% ---------------- 计算1.5s后最终位置 ----------------
% 1. M1最终位置（沿指向假目标方向）
dir_vec_M1 = fake_target - M1_init;
unit_vec_M1 = dir_vec_M1 / norm(dir_vec_M1);
M1_final = M1_init + unit_vec_M1 * (v_M1 * t);  % 运动后坐标

% 2. FY1最终位置（垂直z轴向z轴靠近，z坐标固定）
dir_vec_FY1 = [0-FY1_init(1), 0-FY1_init(2), 0];  % 指向z轴的水平方向
unit_vec_FY1 = dir_vec_FY1 / norm(dir_vec_FY1);
FY1_final = FY1_init + unit_vec_FY1 * (v_FY1 * t);  % 运动后坐标（z=1800不变）

% 3. 真目标圆柱（固定显示）
r = 7; h = 10;
[Xc,Yc,Zc] = cylinder(r,80);
Zc = Zc * h + true_target_center(3);  % 高度缩放+平移
Xc = Xc + true_target_center(1);      % x方向平移
Yc = Yc + true_target_center(2);      % y方向平移

% ---------------- 绘图（仅保留运动后状态） ----------------
figure('Color','w','Position',[100 100 1400 700]);

%% 全局视图（仅显示M1、FY1最终位置与目标）
subplot(1,2,1); hold on; grid on; box on;

% 1. 固定目标（假目标+真目标）
% 假目标（蓝色实心球+标签）
scatter3(fake_target(1),fake_target(2),fake_target(3),150,'b','filled','o');
text(fake_target(1),fake_target(2),fake_target(3)+300,'Fake Target','Color','b','FontSize',10);

% 真目标（全局简化为绿色线段，避免过小看不清）
plot3([0 0 0 0],[200 200 200 200],[0 10 10 0],'g-','LineWidth',3);
text(0,200,50,'True Target','Color','g','FontSize',10);

% 2. M1运动后位置（红色实心圆+加粗标签）
scatter3(M1_final(1),M1_final(2),M1_final(3),120,'r','filled','o','LineWidth',2);
text(M1_final(1),M1_final(2),M1_final(3)+300,'M1 (1.5s Later)','Color','r','FontSize',11,'FontWeight','bold');

% 3. FY1运动后位置（黑色实心三角形+加粗标签）
scatter3(FY1_final(1),FY1_final(2),FY1_final(3),120,'k','filled','^','LineWidth',2);
text(FY1_final(1),FY1_final(2),FY1_final(3)+300,'FY1 (1.5s Later)','Color','k','FontSize',11,'FontWeight','bold');

% 全局视图配置
xlabel('X (m)','FontSize',11); 
ylabel('Y (m)','FontSize',11); 
zlabel('Z (m)','FontSize',11);
title('Global View: M1 & FY1 (After 1.5s Movement)','FontSize',13,'FontWeight','bold');
axis equal; view(30,25);  % 优化视角，清晰展示最终位置
xlim([17000 21000]); ylim([-500 500]); zlim([1500 2500]);  % 聚焦运动后区域

%% 局部视图（仅显示真假目标细节）
subplot(1,2,2); hold on; grid on; box on;

% 假目标（蓝色实心球，放大显示）
[XS,YS,ZS] = sphere(30);
surf(5*XS,5*YS,5*ZS,'FaceColor','b','EdgeColor','none');
text(0,0,20,'Fake Target','Color','b','FontSize',11);

% 真目标（绿色半透明圆柱，增强立体感）
surf(Xc,Yc,Zc,'FaceColor','g','FaceAlpha',0.5,'EdgeColor','none');
text(0,200,15,'True Target (Cylinder)','Color','g','FontSize',11);

% 局部视图配置
xlabel('X (m)','FontSize',11); 
ylabel('Y (m)','FontSize',11); 
zlabel('Z (m)','FontSize',11);
title('Zoomed View: Fake & True Target','FontSize',13,'FontWeight','bold');
axis equal; view(35,30);
xlim([-60,60]); ylim([-60,350]); zlim([0,30]);
camlight headlight; lighting gouraud;  % 光照增强圆柱质感

% ---------------- 关键信息标注 ----------------
annotation('textbox',[0.02,0.02,0.28,0.08],...
    'String',{['M1最终位置: (',num2str(round(M1_final(1))),', ',num2str(round(M1_final(2))),', ',num2str(round(M1_final(3))),') m'],...
    ['FY1最终位置: (',num2str(round(FY1_final(1))),', ',num2str(round(FY1_final(2))),', ',num2str(round(FY1_final(3))),') m']},...
    'FontSize',10,'BackgroundColor','white','EdgeColor','none');