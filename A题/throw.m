clc; clear; close all;

% ---------------- 1. 基础参数与运动起点 ----------------
% 前序1.5s后最终位置（本次运动起点）
M1_start = [19550, 0, 1550];      % M1起点
FY1_pos = [17620, 0, 1800];       % FY1位置（烟雾球抛出点）
fake_target = [0, 0, 0];          % 假目标
true_target_center = [0, 200, 0]; % 真目标圆柱中心

% 本次运动参数
t_total = 3.6;                     % 总运动时间（s）
v_M1 = 300;                        % M1速度（m/s）
v_smoke_horiz = 120;               % 烟雾球水平速度（m/s）
g = 9.8;                           % 重力加速度（m/s²）
smoke_radius = 10;                 % 烟雾球实际半径（m）
display_radius = 30;               % 显示半径（放大3倍，视觉更醒目）
n_points = 50;                     % 抛线采样点数

% ---------------- 2. 运动计算 ----------------
%% 2.1 M1运动
dir_vec_M1 = fake_target - M1_start;
unit_vec_M1 = dir_vec_M1 / norm(dir_vec_M1);
dis_M1 = v_M1 * t_total;
M1_end = M1_start + unit_vec_M1 * dis_M1;

%% 2.2 烟雾球平抛运动（含抛线）
dir_vec_smoke = [0 - FY1_pos(1), 0 - FY1_pos(2), 0];
unit_vec_smoke = dir_vec_smoke / norm(dir_vec_smoke);
t_samp = linspace(0, t_total, n_points);
smoke_traj = zeros(n_points, 3);

for i = 1:n_points
    t = t_samp(i);
    horiz_dis = v_smoke_horiz * t;
    smoke_traj(i, 1:2) = FY1_pos(1:2) + unit_vec_smoke(1:2) * horiz_dis;
    smoke_traj(i, 3) = FY1_pos(3) + 0.5 * (-g) * t^2;  % 竖直下落
end
smoke_end = smoke_traj(end, :);

% ---------------- 3. 绘图元素生成 ----------------
%% 3.1 真目标圆柱
r_target = 7; h_target = 10;
[Xc,Yc,Zc] = cylinder(r_target, 80);
Zc = Zc * h_target + true_target_center(3);
Xc = Xc + true_target_center(1);
Yc = Yc + true_target_center(2);

%% 3.2 烟雾球（放大显示）
[Xs,Ys,Zs] = sphere(50);
Xs = Xs * display_radius + smoke_end(1);  % 使用放大后的显示半径
Ys = Ys * display_radius + smoke_end(2);
Zs = Zs * display_radius + smoke_end(3);

% ---------------- 4. 绘图 ----------------
figure('Color','w','Position',[100 100 1000 700]); hold on; grid on; box on;

% 4.1 固定目标
scatter3(fake_target(1), fake_target(2), fake_target(3), 150, 'b', 'filled', 'o');
text(fake_target(1), fake_target(2), fake_target(3)+300, 'Fake Target', 'Color', 'b', 'FontSize', 11);

surf(Xc, Yc, Zc, 'FaceColor', 'g', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
text(true_target_center(1), true_target_center(2)+30, true_target_center(3)+5, 'True Target', 'Color', 'g', 'FontSize', 11);

% 4.2 M1运动
scatter3(M1_start(1), M1_start(2), M1_start(3), 100, 'r', 'o', 'LineWidth', 2, 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'none');
text(M1_start(1), M1_start(2), M1_start(3)+200, 'M1 (Start)', 'Color', 'r', 'FontSize', 10);

scatter3(M1_end(1), M1_end(2), M1_end(3), 120, 'r', 'filled', 'o', 'LineWidth', 2);
text(M1_end(1), M1_end(2), M1_end(3)+200, 'M1 (End, 3.6s)', 'Color', 'r', 'FontSize', 10, 'FontWeight', 'bold');

plot3([M1_start(1), M1_end(1)], [M1_start(2), M1_end(2)], [M1_start(3), M1_end(3)], 'r--', 'LineWidth', 1.5);

% 4.3 烟雾球（抛线改为虚线，球体放大）
% 烟雾球抛线（改为虚线）
plot3(smoke_traj(:,1), smoke_traj(:,2), smoke_traj(:,3), 'Color', [0.6,0.6,0.6], 'LineWidth', 2, 'LineStyle', '--');

% FY1抛出点
scatter3(FY1_pos(1), FY1_pos(2), FY1_pos(3), 100, 'k', 'filled', '^', 'LineWidth', 2);
text(FY1_pos(1), FY1_pos(2), FY1_pos(3)+200, 'FY1 (Launch)', 'Color', 'k', 'FontSize', 10);

% 烟雾球终点（放大显示）
surf(Xs, Ys, Zs, 'FaceColor', [0.6,0.6,0.6], 'FaceAlpha', 0.6, 'EdgeColor', 'none');
text(smoke_end(1), smoke_end(2), smoke_end(3)-80, 'Smoke Sphere', 'Color', [0.4,0.4,0.4], 'FontSize', 10, 'FontWeight', 'bold');

% 4.4 视图配置
xlabel('X (m)', 'FontSize', 12);
ylabel('Y (m)', 'FontSize', 12);
zlabel('Z (m)', 'FontSize', 12);
title('M1 & Smoke Trajectory (3.6s)', 'FontSize', 14, 'FontWeight', 'bold');
axis equal; view(30, 25);
xlim([16000 20000]); ylim([-500 500]); zlim([1500 1900]);
camlight headlight; lighting gouraud;

% 5. 信息标注
smoke_drop = FY1_pos(3) - smoke_end(3);
annotation('textbox', [0.02, 0.02, 0.38, 0.12], ...
    'String', {['烟雾球: 下落高度=', num2str(round(smoke_drop)), 'm，水平位移=', num2str(round(v_smoke_horiz*t_total)), 'm'], ...
    ['显示说明: 烟雾球视觉放大至', num2str(display_radius), 'm（实际半径', num2str(smoke_radius), 'm）']}, ...
    'FontSize', 10, 'BackgroundColor', 'white', 'EdgeColor', 'none');
