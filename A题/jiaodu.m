clc; clear; close all;

%% ---------------- 1. 基础参数 ----------------
M1_initial = [20000, 0, 2000];       
FY1_initial = [17800, 0, 1800];      
fake_target = [0, 0, 0];             
true_target_center = [0, 200, 0];    

t1 = 1.5; t2 = 3.6; t3 = 20;              
t_total = t1 + t2 + t3;              
v_M1 = 300; v_FY1 = 120;             
v_smoke_horiz = 120;                 
v_smoke_vertical = 3;                
g = 9.8;                             
display_radius = 10;                  
n_frames = 251;                      
frame_delay = 0.1;                   

t_vec = linspace(0, t_total, n_frames);

%% ---------------- 2. 计算轨迹 ----------------
M1_positions = zeros(n_frames, 3);
FY1_positions = zeros(n_frames, 3);
smoke_positions = zeros(n_frames, 3);
smoke_exists = false(n_frames,1);
smoke_visible = false(n_frames,1);

dir_vec_M1_initial = fake_target - M1_initial;
unit_vec_M1_initial = dir_vec_M1_initial / norm(dir_vec_M1_initial);

dir_vec_FY1 = [0 - FY1_initial(1), 0 - FY1_initial(2), 0];
unit_vec_FY1 = dir_vec_FY1 / norm(dir_vec_FY1);

M1_5s1 = M1_initial + unit_vec_M1_initial * v_M1 * (t1 + t2);
FY1_5s1 = FY1_initial + unit_vec_FY1 * v_FY1 * t1;

smoke_5s1 = [
    FY1_5s1(1) + unit_vec_FY1(1) * v_smoke_horiz * t2,
    FY1_5s1(2) + unit_vec_FY1(2) * v_smoke_horiz * t2,
    FY1_5s1(3) - 0.5 * g * t2^2
];

dir_vec_M1_final = fake_target - M1_5s1;
unit_vec_M1_final = dir_vec_M1_final / norm(dir_vec_M1_final);

t_smoke_vec = linspace(0, t2, 50);
smoke_traj = zeros(length(t_smoke_vec),3);
for k = 1:length(t_smoke_vec)
    ts = t_smoke_vec(k);
    smoke_traj(k,:) = [
        FY1_5s1(1) + unit_vec_FY1(1) * v_smoke_horiz * ts,
        FY1_5s1(2) + unit_vec_FY1(2) * v_smoke_horiz * ts,
        FY1_5s1(3) - 0.5 * g * ts^2
    ];
end

for i = 1:n_frames
    t = t_vec(i);
    if t <= t1 + t2
        M1_positions(i,:) = M1_initial + unit_vec_M1_initial * v_M1 * t;
    else
        t_rel = t - (t1 + t2);
        M1_positions(i,:) = M1_5s1 + unit_vec_M1_final * v_M1 * t_rel;
    end
    if t <= t1
        FY1_positions(i,:) = FY1_initial + unit_vec_FY1 * v_FY1 * t;
    else
        FY1_positions(i,:) = FY1_5s1;
    end
    if t > t1 && t <= t1 + t2 + t3
        smoke_exists(i) = true;
        if t <= t1 + t2
            ts = t - t1;
            smoke_positions(i,:) = [
                FY1_5s1(1) + unit_vec_FY1(1) * v_smoke_horiz * ts,
                FY1_5s1(2) + unit_vec_FY1(2) * v_smoke_horiz * ts,
                FY1_5s1(3) - 0.5 * g * ts^2
            ];
            smoke_visible(i) = true;
        else
            ts = t - (t1 + t2);
            smoke_positions(i,:) = [
                smoke_5s1(1),
                smoke_5s1(2),
                smoke_5s1(3) - v_smoke_vertical * ts
            ];
            smoke_visible(i) = (t <= t1 + t2 + t3);
        end
    end
end

%% ---------------- 3. 绘图准备 ----------------
r_target = 7; h_target = 10;
[Xc,Yc,Zc] = cylinder(r_target, 80);
Zc = Zc*h_target + true_target_center(3);
Xc = Xc + true_target_center(1);
Yc = Yc + true_target_center(2);

[Xs,Ys,Zs] = sphere(50);
Xs = Xs*display_radius; Ys = Ys*display_radius; Zs = Zs*display_radius;

%% ---------------- 4. 初始化动画 ----------------
fig = figure('Color','w','Position',[100 100 1200 700]);
hold on; grid on; box on;
xlabel('X (m)','FontSize',12); ylabel('Y (m)','FontSize',12); zlabel('Z (m)','FontSize',12);
title('Missile and Smoke Ball Animation','FontSize',14);
xlim([-500 21000]); ylim([-500 500]); zlim([0 2200]);

axis equal   % <<< 关键，保证烟雾球为真实球体

% 固定视角
campos([10000 -5000 3000]);   
camtarget([8000 100 1000]);   
camup([0 0 1]);              
camlight headlight; lighting gouraud;

% 目标
scatter3(fake_target(1), fake_target(2), fake_target(3), 150, 'b', 'filled', 'o');
text(fake_target(1), fake_target(2), fake_target(3)+300, 'Fake Target', 'Color', 'b', 'FontSize', 11);
surf(Xc,Yc,Zc,'FaceColor','g','FaceAlpha',0.5,'EdgeColor','none');
text(true_target_center(1), true_target_center(2)+50, true_target_center(3), 'True Target', 'Color','g','FontSize',11);

% 运动物体
M1_handle = scatter3(M1_positions(1,1), M1_positions(1,2), M1_positions(1,3), 60, 'r', 'filled', 'o');
FY1_handle = scatter3(FY1_positions(1,1), FY1_positions(1,2), FY1_positions(1,3), 50, 'k', 'filled', '^');
smoke_handle = surf(Xs + smoke_positions(1,1), Ys + smoke_positions(1,2), Zs + smoke_positions(1,3), ...
                    'FaceColor',[0.6 0.6 0.6],'FaceAlpha',0.6,'EdgeColor','none');
set(smoke_handle,'Visible','off');

% 虚线
smoke_traj_handle = plot3([],[],[],'--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5);
missile2target_handle = plot3([M1_positions(1,1), true_target_center(1)], ...
                              [M1_positions(1,2), true_target_center(2)], ...
                              [M1_positions(1,3), true_target_center(3)], '--r', 'LineWidth', 1.5);

time_text = text(18000, 300, 2100, 'Time: 0.0s','FontSize',12,'FontWeight','bold');
status_text = text(18000, 300, 1950, 'Phase: Initial','FontSize',12);

gif_filename = 'missile_smoke_animation_final_ball.gif';

%% ---------------- 5. 逐帧更新动画 ----------------
for i = 1:n_frames
    % M1/FY1
    set(M1_handle,'XData',M1_positions(i,1),'YData',M1_positions(i,2),'ZData',M1_positions(i,3));
    set(FY1_handle,'XData',FY1_positions(i,1),'YData',FY1_positions(i,2),'ZData',FY1_positions(i,3));
    
    % 烟雾球
    if smoke_exists(i) && smoke_visible(i)
        set(smoke_handle,'XData',Xs+smoke_positions(i,1),'YData',Ys+smoke_positions(i,2),'ZData',Zs+smoke_positions(i,3),'Visible','on');
    else
        set(smoke_handle,'Visible','off');
    end
    
    % 导弹-真目标虚线
    set(missile2target_handle,'XData',[M1_positions(i,1),true_target_center(1)],...
                              'YData',[M1_positions(i,2),true_target_center(2)],...
                              'ZData',[M1_positions(i,3),true_target_center(3)]);
    
    % 烟雾虚抛轨迹
    if t_vec(i) > t1
        set(smoke_traj_handle,'XData',smoke_traj(:,1),'YData',smoke_traj(:,2),'ZData',smoke_traj(:,3));
    else
        set(smoke_traj_handle,'XData',[],'YData',[],'ZData',[]);
    end
    
    % 状态文本
    set(time_text,'String',['Time: ', sprintf('%.1f', t_vec(i)),'s']);
    if t_vec(i)<=t1
        set(status_text,'String','Phase: M1 & FY1 Moving');
    elseif t_vec(i)<=t1+t2
        set(status_text,'String','Phase: Smoke Ball平抛');
    else
        set(status_text,'String','Phase: Smoke Ball下落');
    end
    
    drawnow;
    
    % 保存GIF
    frame = getframe(gcf);
    im = frame2im(frame);
    [imind,cm] = rgb2ind(im,256);
    if i==1
        imwrite(imind,cm,gif_filename,'gif','Loopcount',inf,'DelayTime',frame_delay);
    else
        imwrite(imind,cm,gif_filename,'gif','WriteMode','append','DelayTime',frame_delay);
    end
end

disp(['最终动画已保存为: ', gif_filename]);
