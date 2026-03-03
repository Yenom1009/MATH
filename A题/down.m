clc; clear; close all;

% ---------------- 1. 基础参数设置（5.1秒时的状态） ----------------
% 5.1秒时各物体位置（与前序动画衔接）
M1_5s1 = [18470, 0, 1435];         % M1在5.1秒时的位置
FY1_5s1 = [17620, 0, 1800];        % FY1固定位置
smoke_5s1 = [17188, 0, 1736];      % 烟雾球在5.1秒时的位置
fake_target = [0, 0, 0];           % 假目标（原点）
true_target_center = [0, 200, 0];  % 真目标位置

% 运动参数
v_M1 = 300;                        % M1速度（m/s，持续飞向原点）
v_smoke = 3;                       % 烟雾球下落速度（m/s）
smoke_lifespan = 20;               % 烟雾球持续时间（20秒后消失）
display_radius = 30;               % 烟雾球显示半径
n_frames = 200;                    % 总帧数（200帧=20秒）
frame_delay = 0.1;                 % 帧间隔（0.1秒/帧）

% 时间向量（从5.1秒到5.1+20秒）
t_start = 5.1;
t_end = t_start + smoke_lifespan;
t_vec = linspace(t_start, t_end, n_frames);
t_rel = t_vec - t_start;           % 相对时间（0-20秒）

% ---------------- 2. 计算运动轨迹 ----------------
M1_positions = zeros(n_frames, 3);
smoke_positions = zeros(n_frames, 3);
smoke_visible = true(n_frames, 1); % 烟雾球可见性（20秒后为false）

% M1方向向量（始终指向原点）
dir_vec_M1 = fake_target - M1_5s1;
unit_vec_M1 = dir_vec_M1 / norm(dir_vec_M1);

for i = 1:n_frames
    t = t_rel(i);
    
    % M1运动（持续飞向原点，不判断是否到达）
    M1_positions(i,:) = M1_5s1 + unit_vec_M1 * v_M1 * t;
    
    % 烟雾球运动（匀速竖直下落）
    smoke_positions(i,:) = [
        smoke_5s1(1),  % x坐标不变
        smoke_5s1(2),  % y坐标不变
        smoke_5s1(3) - v_smoke * t  % z坐标随时间减小（下落）
    ];
    
    % 20秒后烟雾球消失
    if t >= smoke_lifespan
        smoke_visible(i) = false;
    end
end

% ---------------- 3. 绘图元素准备 ----------------
% 真目标圆柱
r_target = 7; h_target = 10;
[Xc,Yc,Zc] = cylinder(r_target, 80);
Zc = Zc * h_target + true_target_center(3);
Xc = Xc + true_target_center(1);
Yc = Yc + true_target_center(2);

% 烟雾球网格
[Xs,Ys,Zs] = sphere(50);
Xs = Xs * display_radius;
Ys = Ys * display_radius;
Zs = Zs * display_radius;

% ---------------- 4. 生成动画 ----------------
fig = figure('Color','w','Position',[100 100 1000 700]);
hold on; grid on; box on;
xlabel('X (m)','FontSize',12);
ylabel('Y (m)','FontSize',12);
zlabel('Z (m)','FontSize',12);
title('Movement Until Smoke Disappears (5.1s to 25.1s)','FontSize',14);
xlim([-500 19000]);
ylim([-500 500]);
zlim([0 2000]);
view(30,25);
camlight headlight; lighting gouraud;

% 固定目标
scatter3(fake_target(1), fake_target(2), fake_target(3), 150, 'b', 'filled', 'o');
text(fake_target(1), fake_target(2), fake_target(3)+300, 'Fake Target', 'Color', 'b', 'FontSize', 11);
surf(Xc, Yc, Zc, 'FaceColor', 'g', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
text(true_target_center(1), true_target_center(2)+50, true_target_center(3), 'True Target', 'Color', 'g', 'FontSize', 11);

% FY1（固定）
scatter3(FY1_5s1(1), FY1_5s1(2), FY1_5s1(3), 100, 'k', 'filled', '^');
text(FY1_5s1(1), FY1_5s1(2), FY1_5s1(3)+200, 'FY1', 'Color', 'k', 'FontSize', 10);

% 初始化运动物体
M1_handle = scatter3(M1_positions(1,1), M1_positions(1,2), M1_positions(1,3), 120, 'r', 'filled', 'o');
smoke_handle = surf(Xs + smoke_positions(1,1), Ys + smoke_positions(1,2), Zs + smoke_positions(1,3), ...
                    'FaceColor', [0.6,0.6,0.6], 'FaceAlpha', 0.6, 'EdgeColor', 'none');

% 时间标签
time_text = text(15000, 300, 1900, ['Time: ', sprintf('%.1f', t_vec(1)), 's'], 'FontSize', 12, 'FontWeight', 'bold');
smoke_status = text(15000, 300, 1750, 'Smoke: Visible', 'FontSize', 12, 'Color', [0.4,0.4,0.4]);

% 创建GIF文件
gif_filename = 'smoke_until_disappearance.gif';

% 逐帧更新
for i = 1:n_frames
    % 更新M1位置（持续飞行，不判断是否到达目标）
    if isvalid(M1_handle)
        set(M1_handle, 'XData', M1_positions(i,1), 'YData', M1_positions(i,2), 'ZData', M1_positions(i,3));
    else
        M1_handle = scatter3(M1_positions(i,1), M1_positions(i,2), M1_positions(i,3), 120, 'r', 'filled', 'o');
    end
    
    % 更新烟雾球（20秒内显示，之后消失）
    if smoke_visible(i)
        if isvalid(smoke_handle)
            set(smoke_handle, 'XData', Xs + smoke_positions(i,1), ...
                              'YData', Ys + smoke_positions(i,2), ...
                              'ZData', Zs + smoke_positions(i,3));
            set(smoke_handle, 'Visible', 'on');
        else
            smoke_handle = surf(Xs + smoke_positions(i,1), Ys + smoke_positions(i,2), Zs + smoke_positions(i,3), ...
                               'FaceColor', [0.6,0.6,0.6], 'FaceAlpha', 0.6, 'EdgeColor', 'none');
        end
        set(smoke_status, 'String', 'Smoke: Visible');
    else
        if isvalid(smoke_handle)
            set(smoke_handle, 'Visible', 'off');
        end
        set(smoke_status, 'String', 'Smoke: Disappeared');
    end
    
    % 更新时间标签
    set(time_text, 'String', ['Time: ', sprintf('%.1f', t_vec(i)), 's']);
    
    % 刷新画面
    drawnow;
    
    % 保存帧到GIF
    frame = getframe(gcf);  % 使用当前图形句柄，确保有效性
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);
    
    if i == 1
        imwrite(imind, cm, gif_filename, 'gif', 'Loopcount', inf, 'DelayTime', frame_delay);
    else
        imwrite(imind, cm, gif_filename, 'gif', 'WriteMode', 'append', 'DelayTime', frame_delay);
    end
end

disp(['动画已保存为: ', gif_filename]);
        