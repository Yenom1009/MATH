clc; clear; close all;

% ---------------- 1. 基础参数设置 ----------------
% 初始位置（t=0时）
M1_initial = [20000, 0, 2000];       % M1初始位置
FY1_initial = [17800, 0, 1800];      % FY1初始位置
fake_target = [0, 0, 0];             % 假目标（原点）
true_target_center = [0, 200, 0];    % 真目标位置

% 运动参数
t1 = 1.5;                            % 第一阶段时间（s）
t2 = 3.6;                            % 第二阶段时间（s）
t3 = 20;                             % 第三阶段时间（s，烟雾球消失）
t_total = t1 + t2 + t3;              % 总时长25.1秒
v_M1 = 300;                          % M1速度（m/s）
v_FY1 = 120;                         % FY1第一阶段速度（m/s）
v_smoke_horiz = 120;                 % 烟雾球水平速度（m/s）
v_smoke_vertical = 3;                % 烟雾球下落速度（m/s）
g = 9.8;                             % 重力加速度
display_radius = 30;                 % 烟雾球显示半径
n_frames = 251;                      % 总帧数（约10帧/秒）
frame_delay = 0.1;                   % 帧间隔时间（s）

% 时间向量（0到25.1秒）
t_vec = linspace(0, t_total, n_frames);

% ---------------- 2. 计算完整运动轨迹 ----------------
% 存储各帧位置
M1_positions = zeros(n_frames, 3);
FY1_positions = zeros(n_frames, 3);
smoke_positions = zeros(n_frames, 3);
smoke_exists = false(n_frames, 1);   % 烟雾球是否存在
smoke_visible = false(n_frames, 1);  % 烟雾球是否可见

% 预计算方向向量
dir_vec_M1_initial = fake_target - M1_initial;
unit_vec_M1_initial = dir_vec_M1_initial / norm(dir_vec_M1_initial);

dir_vec_FY1 = [0 - FY1_initial(1), 0 - FY1_initial(2), 0];
unit_vec_FY1 = dir_vec_FY1 / norm(dir_vec_FY1);

% 计算5.1秒时的关键位置（用于第三阶段）
M1_5s1 = M1_initial + unit_vec_M1_initial * v_M1 * (t1 + t2);
FY1_5s1 = FY1_initial + unit_vec_FY1 * v_FY1 * t1;  % FY1在1.5s后静止

% 烟雾球在5.1秒时的位置
smoke_5s1_x = FY1_5s1(1) + unit_vec_FY1(1) * v_smoke_horiz * t2;
smoke_5s1_y = FY1_5s1(2) + unit_vec_FY1(2) * v_smoke_horiz * t2;
smoke_5s1_z = FY1_5s1(3) - 0.5 * g * t2^2;
smoke_5s1 = [smoke_5s1_x, smoke_5s1_y, smoke_5s1_z];

% M1第三阶段方向向量
dir_vec_M1_final = fake_target - M1_5s1;
unit_vec_M1_final = dir_vec_M1_final / norm(dir_vec_M1_final);

% 计算所有帧位置
for i = 1:n_frames
    t = t_vec(i);
    
    % 1. M1运动（全程）
    if t <= t1 + t2  % 前5.1秒
        M1_positions(i,:) = M1_initial + unit_vec_M1_initial * v_M1 * t;
    else  % 5.1秒后
        t_rel = t - (t1 + t2);
        M1_positions(i,:) = M1_5s1 + unit_vec_M1_final * v_M1 * t_rel;
    end
    
    % 2. FY1运动（1.5秒后静止）
    if t <= t1
        FY1_positions(i,:) = FY1_initial + unit_vec_FY1 * v_FY1 * t;
    else
        FY1_positions(i,:) = FY1_5s1;  % 保持1.5秒后的位置
    end
    
    % 3. 烟雾球运动（1.5-5.1秒平抛，5.1-25.1秒匀速下落）
    if t > t1 && t <= t1 + t2 + t3  % 1.5秒后出现，25.1秒前可见
        smoke_exists(i) = true;
        if t <= t1 + t2  % 平抛阶段（1.5-5.1秒）
            t_smoke = t - t1;
            smoke_positions(i,:) = [
                FY1_5s1(1) + unit_vec_FY1(1) * v_smoke_horiz * t_smoke,
                FY1_5s1(2) + unit_vec_FY1(2) * v_smoke_horiz * t_smoke,
                FY1_5s1(3) - 0.5 * g * t_smoke^2
            ];
            smoke_visible(i) = true;
        else  % 匀速下落阶段（5.1-25.1秒）
            t_smoke = t - (t1 + t2);
            smoke_positions(i,:) = [
                smoke_5s1(1),
                smoke_5s1(2),
                smoke_5s1(3) - v_smoke_vertical * t_smoke
            ];
            smoke_visible(i) = (t <= t1 + t2 + t3);  % 25.1秒后不可见
        end
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

% ---------------- 4. 生成完整动画 ----------------
fig = figure('Color','w','Position',[100 100 1000 700]);
hold on; grid on; box on;
xlabel('X (m)','FontSize',12);
ylabel('Y (m)','FontSize',12);
zlabel('Z (m)','FontSize',12);
title('Complete Movement Animation (0s to 25.1s)','FontSize',14);
xlim([-500 21000]);
ylim([-500 500]);
zlim([0 2200]);
view(30,25);
camlight headlight; lighting gouraud;

% 固定目标
scatter3(fake_target(1), fake_target(2), fake_target(3), 150, 'b', 'filled', 'o');
text(fake_target(1), fake_target(2), fake_target(3)+300, 'Fake Target', 'Color', 'b', 'FontSize', 11);
surf(Xc, Yc, Zc, 'FaceColor', 'g', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
text(true_target_center(1), true_target_center(2)+50, true_target_center(3), 'True Target', 'Color', 'g', 'FontSize', 11);

% 初始化运动物体句柄
M1_handle = scatter3(M1_positions(1,1), M1_positions(1,2), M1_positions(1,3), 120, 'r', 'filled', 'o');
FY1_handle = scatter3(FY1_positions(1,1), FY1_positions(1,2), FY1_positions(1,3), 100, 'k', 'filled', '^');
smoke_handle = surf(Xs + smoke_positions(1,1), Ys + smoke_positions(1,2), Zs + smoke_positions(1,3), ...
                    'FaceColor', [0.6,0.6,0.6], 'FaceAlpha', 0.6, 'EdgeColor', 'none');
set(smoke_handle, 'Visible', 'off');  % 初始隐藏

% 状态标签
time_text = text(18000, 300, 2100, 'Time: 0.0s', 'FontSize', 12, 'FontWeight', 'bold');
status_text = text(18000, 300, 1950, 'Phase: Initial', 'FontSize', 12);

% 创建GIF文件
gif_filename = 'complete_missile_smoke_animation.gif';

% 逐帧更新动画
for i = 1:n_frames
    % 确保图形窗口有效
    if ~isvalid(fig)
        fig = figure('Color','w','Position',[100 100 1000 700]);
        hold on; grid on; box on;
    end
    
    % 更新M1位置
    if isvalid(M1_handle)
        set(M1_handle, 'XData', M1_positions(i,1), 'YData', M1_positions(i,2), 'ZData', M1_positions(i,3));
    else
        M1_handle = scatter3(M1_positions(i,1), M1_positions(i,2), M1_positions(i,3), 120, 'r', 'filled', 'o');
    end
    
    % 更新FY1位置
    if isvalid(FY1_handle)
        set(FY1_handle, 'XData', FY1_positions(i,1), 'YData', FY1_positions(i,2), 'ZData', FY1_positions(i,3));
    else
        FY1_handle = scatter3(FY1_positions(i,1), FY1_positions(i,2), FY1_positions(i,3), 100, 'k', 'filled', '^');
    end
    
    % 更新烟雾球
    if smoke_exists(i) && smoke_visible(i)
        if isvalid(smoke_handle)
            set(smoke_handle, 'XData', Xs + smoke_positions(i,1), ...
                              'YData', Ys + smoke_positions(i,2), ...
                              'ZData', Zs + smoke_positions(i,3));
            set(smoke_handle, 'Visible', 'on');
        else
            smoke_handle = surf(Xs + smoke_positions(i,1), Ys + smoke_positions(i,2), Zs + smoke_positions(i,3), ...
                               'FaceColor', [0.6,0.6,0.6], 'FaceAlpha', 0.6, 'EdgeColor', 'none');
        end
    else
        if isvalid(smoke_handle)
            set(smoke_handle, 'Visible', 'off');
        end
    end
    
    % 更新状态文本
    set(time_text, 'String', ['Time: ', sprintf('%.1f', t_vec(i)), 's']);
    if t_vec(i) <= t1
        set(status_text, 'String', 'Phase: M1 & FY1 Moving');
    elseif t_vec(i) <= t1 + t2
        set(status_text, 'String', 'Phase: Smoke Ball平抛');
    else
        set(status_text, 'String', 'Phase: Smoke Ball下落');
    end
    
    % 刷新画面
    drawnow;
    
    % 保存帧到GIF
    frame = getframe(gcf);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);
    
    if i == 1
        imwrite(imind, cm, gif_filename, 'gif', 'Loopcount', inf, 'DelayTime', frame_delay);
    else
        imwrite(imind, cm, gif_filename, 'gif', 'WriteMode', 'append', 'DelayTime', frame_delay);
    end
end

disp(['完整动画已保存为: ', gif_filename]);
    