import numpy as np
G = -9.8

def distance_point_to_line_segment(p, a, b):
    """计算点p到线段ab的最短距离"""
    if np.all(a == b): return np.linalg.norm(p - a)
    ap, ab = p - a, b - a
    t = np.dot(ap, ab) / np.dot(ab, ab)
    if t < 0.0: return np.linalg.norm(p - a)
    if t > 1.0: return np.linalg.norm(p - b)
    return np.linalg.norm(p - (a + t * ab))

def get_cover_time(particle:np.ndarray, missile_flying_time, output=False):
    """
    计算给定无人机方向、角度、飞行时间和起爆时间时的目标被遮蔽的总时间
    :param particle: 含有参数的粒子，[drone_speed, drone_angle, drone_flying_time, bomb_burst_time]
    :param missile_flying_time: 导弹飞行总时间
    :param output:控制是否输出
    :return: 目标被遮蔽总时间
    """
    drone_speed, drone_angle, drone_flying_time, bomb_burst_time = particle.tolist()
    # 无人机方向、角度、飞行时间、起爆时间
    
    # 若无人机飞行时间+起爆时间>=导弹飞行时间，遮蔽时间为0
    if drone_flying_time + bomb_burst_time >= missile_flying_time:
        return 0
     
    fake_target_location = np.array([0,0,0]) # 假目标位置
    real_target_location_down = np.array([0,200,10]) # 真目标下平面圆心位置
    drone_start_location  = np.array([17800,0,1800]) # 无人机起始位置

    drone_direction = np.array([np.cos(drone_angle),np.sin(drone_angle),0]) # 无人机方向向量

    bomb_start_location = drone_start_location + drone_direction * drone_speed * drone_flying_time # 烟雾弹落下位置
    
    bomb_burst_location_x = bomb_start_location[0] + drone_direction[0] * drone_speed * bomb_burst_time
    bomb_burst_location_y = bomb_start_location[1] + drone_direction[1] * drone_speed * bomb_burst_time
    bomb_burst_location_z = bomb_start_location[2] + G * bomb_burst_time**2 / 2
    bomb_burst_location = np.array([bomb_burst_location_x, bomb_burst_location_y, bomb_burst_location_z]) # 烟雾弹爆炸位置
    
    M1_start_location = np.array([20000,0,2000]) # 导弹起始位置
    M1_speed = 300 # 导弹速度
    M1_direction = (fake_target_location - M1_start_location)/np.linalg.norm(fake_target_location - M1_start_location) # 导弹方向向量

    M1_count_location = M1_start_location + M1_direction * (drone_flying_time + bomb_burst_time) * M1_speed # 烟雾弹爆炸时导弹位置

    if output:
        print(f'烟雾弹抛下位置:{bomb_start_location}')
        print(f'烟雾弹爆炸位置:{bomb_burst_location}')
        print(f'导弹方向:{M1_direction}')
        print(f'烟雾弹爆炸时导弹位置:{M1_count_location}')

    cover = False
    t = 0
    delta_t = 0.005 # 时间步长
    bomb_speed = 3 # 烟雾下落速度
    bomb_direction = np.array([0,0,-1]) # 烟雾下落方向向量
    bomb_location = bomb_burst_location.copy()
    M1_location = M1_count_location.copy()
    cover_time = 0
    while(1):
        bomb_location += delta_t * bomb_speed * bomb_direction
        M1_location += delta_t * M1_speed * M1_direction
        distance = distance_point_to_line_segment(bomb_location, M1_location, real_target_location_down) # 导弹与真目标连线到烟雾中心距离
        distance_M_bomb = np.linalg.norm(M1_location - bomb_location)
        if not cover and distance <= 10:
            cover = True
            start_time = t
        if cover and distance > 10:
            cover = False
            end_time = t
            cover_time += end_time - start_time
        t += delta_t
        if t >= 20:
            if cover:
                end_time = t
                cover_time += end_time - start_time
            break
    if output:
        print(f'开始遮蔽时间:{start_time:.3f} s')
        print(f'结束遮蔽时间:{end_time:.3f} s')
    return cover_time

print(f'遮蔽时间:{get_cover_time(np.array([120, np.pi, 1.5, 3.6]),missile_flying_time=67,output=True):.3f} s')