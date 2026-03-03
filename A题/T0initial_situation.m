clc; clear; close all;

% ---------------- 数据 ----------------
MISSILES = [20000, 0, 2000; 
            19000, 600, 2100; 
            18000,-600, 1900];
MISSILE_NAMES = {'M1','M2','M3'};

DRONES = [17800, 0, 1800;
          12000,1400,1400;
          6000,-3000,700;
          11000,2000,1800;
          13000,-2000,1300];
DRONE_NAMES = {'FY1','FY2','FY3','FY4','FY5'};

fake_target = [0,0,0];         % 假目标点
true_target_center = [0,200,0];% 真目标圆柱下底圆心

% 真目标圆柱 (半径7, 高10)
r = 7; h = 10;
[Xc,Yc,Zc] = cylinder(r,80);
Zc = Zc * h;
Xc = Xc + true_target_center(1);
Yc = Yc + true_target_center(2);
Zc = Zc + true_target_center(3);

% ---------------- 绘图 ----------------
figure('Color','w','Position',[100 100 1400 700]);

%% 全局视图
subplot(1,2,1); hold on; grid on; box on;

% 假目标
scatter3(fake_target(1),fake_target(2),fake_target(3),120,'b','filled','o');
text(0,0,200,'Fake Target','Color','b');

% 真目标（画个绿色立方体代替，便于在全局尺度下看见）
% plot3([0 0 0 0],[200 200 200 200],[0 10 10 0],'g-','LineWidth',3);
% text(0,200,20,'True Target (zoom in for details)','Color','g');
% 真目标（深绿色立方体，修复颜色格式：用RGB三元组代替十六进制）
% ========== 修复：颜色改为[0 0.4 0]（深绿色RGB），先写线型再写Color参数 ==========
plot3([0 0 0 0],[200 200 200 200],[0 10 10 0],'-',...
      'Color',[0 0.4 0],'LineWidth',4);
text(0,200,20,'True Target (zoom in for details)','Color',[0 0.4 0],'FontWeight','bold');

% 导弹
scatter3(MISSILES(:,1),MISSILES(:,2),MISSILES(:,3),80,'r','filled');
for i=1:3
    text(MISSILES(i,1),MISSILES(i,2),MISSILES(i,3)+200,MISSILE_NAMES{i},'Color','r');
end

% 添加导弹指向假目标的短箭头
% 计算箭头方向向量
arrow_length = 1000;  % 箭头长度，可根据需要调整
for i = 1:3
    % 计算从导弹到假目标的方向向量
    dir_vec = fake_target - MISSILES(i,:);
    % 归一化方向向量
    dir_vec_norm = dir_vec / norm(dir_vec);
    % 计算箭头终点（从导弹位置出发，沿方向向量移动arrow_length距离）
    arrow_end = MISSILES(i,:) + dir_vec_norm * arrow_length;
    
    % 绘制箭头
    quiver3(MISSILES(i,1), MISSILES(i,2), MISSILES(i,3), ...
            arrow_end(1)-MISSILES(i,1), arrow_end(2)-MISSILES(i,2), arrow_end(3)-MISSILES(i,3), ...
            0, 'Color', 'r', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
end

% 无人机
scatter3(DRONES(:,1),DRONES(:,2),DRONES(:,3),100,'k','^','filled');
for i=1:5
    text(DRONES(i,1),DRONES(i,2),DRONES(i,3)+200,DRONE_NAMES{i},'Color','k');
end

xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
title('Global View: Missiles, Drones, Fake & True Targets');
axis equal; view(30,20);
xlim([-1000 21000]); ylim([-4000 4000]); zlim([0 2500]);

%% 局部视图（只看真假目标）
subplot(1,2,2); hold on; grid on; box on;

% 假目标 (蓝色小球)
[XS,YS,ZS] = sphere(30);
surf(5*XS,5*YS,5*ZS,'FaceColor','b','EdgeColor','none');
text(0,0,15,'Fake Target','Color','b');

% 真目标 (绿色圆柱)
surf(Xc,Yc,Zc,'FaceColor','g','FaceAlpha',0.4,'EdgeColor','none');
% ========== 颜色修改：从'g'改为'#006600'（深绿色），FaceAlpha=1（不透明） ==========
text(0,200,12,'True Target (cylinder)','Color','#006600','FontWeight','bold');

xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
title('Zoomed View: Fake vs. True Target');
axis equal; view(35,25);
xlim([-50,50]); ylim([-50,300]); zlim([0,20]);
camlight headlight; lighting gouraud;