clc; clear; close all;

% ---------------- 1. 基础参数设置 ----------------
% 初始位置（t=0时）
M1_initial = [20000, 0, 2000];       % M1初始位置
FY1_initial = [17800, 0, 1800];      % FY1初始位置
fake_target = [0, 0, 0];             % 假目标
true_target_center = [0, 200, 0];    % 真目标中心

% 运动参数
t1 = 1.5;                            % 第一阶段时间（s）
t2 = 3.6;                            % 第二阶段时间（s）
t_total = t1 + t2;                   % 总时间（5.1s）
v_M1 = 300;                          % M1速度（m/s）
v_FY1 = 120;                         % FY1第一阶段速度（m/s）
v_smoke = 120;                       % 烟雾球水平速度（m/s）
g = 9.8;                             % 重力加速度（m/s²）
smoke_radius = 10;                   % 烟雾球实际半径
display_radius = 30;                 % 烟雾球显示半径（放大）
n_frames = 51;                       % 总帧数（每秒约10帧）
frame_delay = 0.1;                   % 帧间隔时间（s）

% ---------------- 2. 计算各阶段运动轨迹 ----------------
% 时间向量（0到总时间，均匀采样）
t_vec = linspace(0, t_total, n_frames);

% 存储各帧位置的数组
M1_positions = zeros(n_frames, 3);
FY1_positions = zeros(n_frames, 3);
smoke_positions = zeros(n_frames, 3);
smoke_exists = false(n_frames, 1);   % 标记烟雾球是否已抛出

% 预计算M1在1.5s时的位置（用于第二阶段计算）
dir_vec_M1_t1 = fake_target - M1_initial;
unit_vec_M1_t1 = dir_vec_M1_t1 / norm(dir_vec_M1_t1);
M1_t1 = M1_initial + unit_vec_M1_t1 * v_M1 * t1;

% 预计算FY1在1.5s时的位置
dir_vec_FY1_t1 = [0 - FY1_initial(1), 0 - FY1_initial(2), 0];
unit_vec_FY1_t1 = dir_vec_FY1_t1 / norm(dir_vec_FY1_t1);
FY1_t1 = FY1_initial + unit_vec_FY1_t1 * v_FY1 * t1;

% 计算所有帧的位置
for i = 1:n_frames
    t = t_vec(i);
    
    % M1位置计算
    if t <= t1
        M1_positions(i,:) = M1_initial + unit_vec_M1_t1 * v_M1 * t;
    else
        dir_vec_M1 = fake_target - M1_t1;
        unit_vec_M1 = dir_vec_M1 / norm(dir_vec_M1);
        M1_positions(i,:) = M1_t1 + unit_vec_M1 * v_M1 * (t - t1);
    end
    
    % FY1位置计算
    if t <= t1
        FY1_positions(i,:) = FY1_initial + unit_vec_FY1_t1 * v_FY1 * t;
    else
        FY1_positions(i,:) = FY1_t1;
    end
    
    % 烟雾球位置计算（仅第二阶段）
    if t > t1
        smoke_exists(i) = true;
        t_smoke = t - t1;
        
        % 水平方向
        dir_vec_smoke = [0 - FY1_t1(1), 0 - FY1_t1(2), 0];
        unit_vec_smoke = dir_vec_smoke / norm(dir_vec_smoke);
        horiz_dis = v_smoke * t_smoke;
        
        % 竖直方向
        vert_dis = 0.5 * (-g) * t_smoke^2;
        
        smoke_positions(i,:) = [FY1_t1(1) + unit_vec_smoke(1)*horiz_dis, ...
                               FY1_t1(2) + unit_vec_smoke(2)*horiz_dis, ...
                               FY1_t1(3) + vert_dis];
    end
end

% ---------------- 3. 真目标圆柱和烟雾球网格 ----------------
% 真目标圆柱
r_target = 7; h_target = 10;
[Xc,Yc,Zc] = cylinder(r_target, 80);
Zc = Zc * h_target + true_target_center(3);
Xc = Xc + true_target_center(1);
Yc = Yc + true_target_center(2);

% 烟雾球网格（用于显示）
[Xs,Ys,Zs] = sphere(50);
Xs = Xs * display_radius;
Ys = Ys * display_radius;
Zs = Zs * display_radius;

% ---------------- 4. 生成动画 ----------------
% 创建图形窗口
fig = figure('Color','w','Position',[100 100 1000 700]);
hold on;  % 关键：保持图形，防止对象被清除
axis equal; grid on; box on;
xlabel('X (m)','FontSize',12);
ylabel('Y (m)','FontSize',12);
zlabel('Z (m)','FontSize',12);
title('Missile and Smoke Movement Animation (Total 5.1s)','FontSize',14);
xlim([16000 21000]); ylim([-500 500]); zlim([1500 2200]);
view(30,25);
camlight headlight; lighting gouraud;

% 绘制固定目标
scatter3(fake_target(1), fake_target(2), fake_target(3), 150, 'b', 'filled', 'o');
text(fake_target(1), fake_target(2), fake_target(3)+300, 'Fake Target', 'Color', 'b', 'FontSize', 11);
surf(Xc, Yc, Zc, 'FaceColor', 'g', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
text(true_target_center(1), true_target_center(2)+30, true_target_center(3)+5, 'True Target', 'Color', 'g', 'FontSize', 11);

% 初始化运动物体（在hold on之后创建，确保对象被保留）
M1_handle = scatter3(M1_positions(1,1), M1_positions(1,2), M1_positions(1,3), 120, 'r', 'filled', 'o');
FY1_handle = scatter3(FY1_positions(1,1), FY1_positions(1,2), FY1_positions(1,3), 100, 'k', 'filled', '^');
smoke_handle = surf(Xs + smoke_positions(1,1), Ys + smoke_positions(1,2), Zs + smoke_positions(1,3), ...
                    'FaceColor', [0.6,0.6,0.6], 'FaceAlpha', 0.6, 'EdgeColor', 'none');
smoke_handle.Visible = 'off';  % 初始隐藏烟雾球

% 时间标签
time_text = text(16200, 300, 2100, ['Time: 0.0s'], 'FontSize', 12, 'FontWeight', 'bold');

% 创建GIF文件
gif_filename = 'missile_animation.gif';

% 逐帧更新
for i = 1:n_frames
    % 检查对象是否存在，不存在则重新创建
    if ~isvalid(M1_handle)
        M1_handle = scatter3(M1_positions(i,1), M1_positions(i,2), M1_positions(i,3), 120, 'r', 'filled', 'o');
    else
        set(M1_handle, 'XData', M1_positions(i,1), 'YData', M1_positions(i,2), 'ZData', M1_positions(i,3));
    end
    
    if ~isvalid(FY1_handle)
        FY1_handle = scatter3(FY1_positions(i,1), FY1_positions(i,2), FY1_positions(i,3), 100, 'k', 'filled', '^');
    else
        set(FY1_handle, 'XData', FY1_positions(i,1), 'YData', FY1_positions(i,2), 'ZData', FY1_positions(i,3));
    end
    
    % 更新烟雾球
    if smoke_exists(i)
        if ~isvalid(smoke_handle)
            smoke_handle = surf(Xs + smoke_positions(i,1), Ys + smoke_positions(i,2), Zs + smoke_positions(i,3), ...
                               'FaceColor', [0.6,0.6,0.6], 'FaceAlpha', 0.6, 'EdgeColor', 'none');
        else
            set(smoke_handle, 'XData', Xs + smoke_positions(i,1), 'YData', Ys + smoke_positions(i,2), 'ZData', Zs + smoke_positions(i,3));
        end
        set(smoke_handle, 'Visible', 'on');
    else
        if isvalid(smoke_handle)
            set(smoke_handle, 'Visible', 'off');
        end
    end
    
    % 更新时间标签
    set(time_text, 'String', ['Time: ', sprintf('%.1f', t_vec(i)), 's']);
    
    % 刷新画面
    drawnow;
    
    % 保存为GIF帧
    frame = getframe(fig);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);
    
    % 写入GIF文件
    if i == 1
        imwrite(imind, cm, gif_filename, 'gif', 'Loopcount', inf, 'DelayTime', frame_delay);
    else
        imwrite(imind, cm, gif_filename, 'gif', 'WriteMode', 'append', 'DelayTime', frame_delay);
    end
end

disp(['动画已保存为: ', gif_filename]);