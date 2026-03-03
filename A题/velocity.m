clc; clear; close all;

% ---------------- 基础数据与运动参数 ----------------
% 1. 初始位置数据（FY1初始在x=17800、y=0，离z轴有距离）
M1_init = [20000, 0, 2000];       % M1初始坐标
FY1_init = [17800, 0, 1800];      % FY1初始坐标（z=1800固定，x=17800离z轴远）
fake_target = [0, 0, 0];          % 假目标（固定）
true_target_center = [0, 200, 0]; % 真目标圆柱中心（固定）

% 2. 运动参数（核心：FY1方向指向z轴）
t = 1.5;                          % 运动时间（s）
v_M1 = 300;                       % M1速度（m/s，沿指向假目标方向）
v_FY1 = 120;                      % FY1速度（m/s，垂直z轴且指向z轴）

% ---------------- 计算运动后位置（关键修正FY1方向） ----------------
% 1. M1运动计算（沿指向假目标，逻辑不变）
dir_vec_M1 = fake_target - M1_init;  % M1到假目标的方向向量
unit_vec_M1 = dir_vec_M1 / norm(dir_vec_M1);  % 归一化方向
dis_M1 = v_M1 * t;                  % M1运动距离（300*1.5=450m）
M1_final = M1_init + unit_vec_M1 * dis_M1;    % M1靠近假目标

% 2. FY1运动计算（核心：指向z轴，且垂直z轴）
% z轴在x-y平面的投影是原点(0,0)，FY1指向z轴即指向(0,0)（x-y平面内）
dir_vec_FY1 = [0 - FY1_init(1), 0 - FY1_init(2), 0];  % 方向向量：(0-FY1.x, 0-FY1.y, 0)（z分量=0，垂直z轴）
unit_vec_FY1 = dir_vec_FY1 / norm(dir_vec_FY1);        % 归一化方向（确保速度方向准确）
dis_FY1 = v_FY1 * t;                                  % FY1运动距离（120*1.5=180m）
FY1_final = FY1_init + unit_vec_FY1 * dis_FY1;        % FY1向z轴靠近（x减小，y不变，z固定）

% 验证FY1是否离z轴更近：计算运动前后到z轴的距离（x-y平面内到原点的距离）
dist_FY1_init = norm(FY1_init(1:2));  % 初始距离：sqrt(17800²+0²)=17800m
dist_FY1_final = norm(FY1_final(1:2));% 运动后距离：17800-180=17620m（更近）

% ---------------- 绘图（突出FY1靠近z轴） ----------------
figure('Color','w','Position',[100 100 1400 700]);

%% 全局视图（展示运动状态）
subplot(1,2,1); hold on; grid on; box on;

% 1. 固定目标（假目标+真目标）
scatter3(fake_target(1),fake_target(2),fake_target(3),150,'b','filled','o');
text(fake_target(1),fake_target(2),fake_target(3)+300,'Fake Target','Color','b','FontSize',10);
plot3([0 0 0 0],[200 200 200 200],[0 10 10 0],'g-','LineWidth',3);
text(0,200,50,'True Target','Color','g','FontSize',10);

% 2. M1运动前后对比
scatter3(M1_init(1),M1_init(2),M1_init(3),100,'r','o','LineWidth',2,'MarkerEdgeColor','r','MarkerFaceColor','none');
text(M1_init(1),M1_init(2),M1_init(3)+300,'M1 (Initial)','Color','r','FontSize',10);
scatter3(M1_final(1),M1_final(2),M1_final(3),120,'r','filled','o','LineWidth',2);
text(M1_final(1),M1_final(2),M1_final(3)+300,'M1 (1.5s Later)','Color','r','FontSize',10,'FontWeight','bold');
plot3([M1_init(1), M1_final(1)], [M1_init(2), M1_final(2)], [M1_init(3), M1_final(3)], 'r--', 'LineWidth',1.5);

% 3. FY1运动前后对比（突出靠近z轴）
scatter3(FY1_init(1),FY1_init(2),FY1_init(3),100,'k','^','LineWidth',2,'MarkerEdgeColor','k','MarkerFaceColor','none');
text(FY1_init(1),FY1_init(2),FY1_init(3)+300,'FY1 (Initial)','Color','k','FontSize',10);
scatter3(FY1_final(1),FY1_final(2),FY1_final(3),120,'k','filled','^','LineWidth',2);
text(FY1_final(1),FY1_final(2),FY1_final(3)+300,'FY1 (1.5s Later)','Color','k','FontSize',10,'FontWeight','bold');
plot3([FY1_init(1), FY1_final(1)], [FY1_init(2), FY1_final(2)], [FY1_init(3), FY1_final(3)], 'k--', 'LineWidth',1.5);

% 绘制z轴（辅助线，清晰看到FY1向z轴靠近）
plot3([0,0],[0,0],[0,3000],'m-','LineWidth',1.5,'DisplayName','Z轴');
legend('Z轴','Location','best');  % 显示图例，标注z轴

% 全局视图配置
xlabel('X (m)','FontSize',11); 
ylabel('Y (m)','FontSize',11); 
zlabel('Z (m)','FontSize',11);
title('Global View: M1 & FY1 (FY1 Approaches Z-Axis)','FontSize',13,'FontWeight','bold');
axis equal; view(30,25);  % 视角优化，清晰看到FY1向z轴移动
xlim([17000 21000]); ylim([-500 500]); zlim([1500 2500]);  % 聚焦运动区域

%% 局部视图（真假目标细节）
subplot(1,2,2); hold on; grid on; box on;

% 假目标（蓝色实心球）
[XS,YS,ZS] = sphere(30);
surf(5*XS,5*YS,5*ZS,'FaceColor','b','EdgeColor','none');
text(0,0,20,'Fake Target','Color','b','FontSize',11);

% 真目标（绿色半透明圆柱）
r = 7; h = 10;
[Xc,Yc,Zc] = cylinder(r,80);
Zc = Zc * h + true_target_center(3);
Xc = Xc + true_target_center(1);
Yc = Yc + true_target_center(2);
surf(Xc,Yc,Zc,'FaceColor','g','FaceAlpha',0.5,'EdgeColor','none');
text(0,200,15,'True Target (Cylinder)','Color','g','FontSize',11);

% 局部视图配置
xlabel('X (m)','FontSize',11); 
ylabel('Y (m)','FontSize',11); 
zlabel('Z (m)','FontSize',11);
title('Zoomed View: Fake & True Target','FontSize',13,'FontWeight','bold');
axis equal; view(35,30);
xlim([-60,60]); ylim([-60,350]); zlim([0,30]);
camlight headlight; lighting gouraud;

% ---------------- 运动信息标注（明确FY1靠近z轴） ----------------
annotation('textbox',[0.02,0.02,0.32,0.15],...
    'String',{['M1: 速度 ',num2str(v_M1),'m/s，沿指向假目标方向运动'],...
    ['FY1: 速度 ',num2str(v_FY1),'m/s，垂直z轴且向z轴靠近'],...
    ['FY1初始离z轴距离: ',num2str(round(dist_FY1_init)),'m'],...
    ['FY1运动后离z轴距离: ',num2str(round(dist_FY1_final)),'m'],...
    ['运动时间: ',num2str(t),'s']},...
    'FontSize',10,'BackgroundColor','white','EdgeColor','none');