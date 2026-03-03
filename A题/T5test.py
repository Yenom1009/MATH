import numpy as np
import random
import warnings
import copy

# 关闭不必要的警告
warnings.filterwarnings("ignore", category=RuntimeWarning)

# ===== 定义问题常量 =====
FY_INITIAL = [
    np.array([17800, 0, 1800]), 
    np.array([12000, 1400, 1400]),
    np.array([6000, -3000, 700]), 
    np.array([11000, 2000, 1800]),
    np.array([13000, -2000, 1300])
]
M_INITIAL = [
    np.array([20000, 0, 2000]), 
    np.array([19000, 600, 2100]),
    np.array([18000, -600, 1900])
]
MISSILE_TARGET_POINT = np.array([0, 0, 0])
TARGET_CYLINDER_BASE_CENTER = np.array([0, 200, 0])
TARGET_CYLINDER_RADIUS = 7.0
TARGET_CYLINDER_HEIGHT = 10.0
MISSILE_SPEED = 300.0
CLOUD_FALL_SPEED = 3.0
CLOUD_RADIUS = 10.0
CLOUD_EFFECTIVE_DURATION = 20.0
G = 9.8
DRONE_SPEED_BOUNDS = (70.0, 140.0)

# 生成目标圆柱体点集
num_target_points_per_face = 100
angles = np.linspace(0, 2 * np.pi, num_target_points_per_face, endpoint=False)
x_rim = TARGET_CYLINDER_BASE_CENTER[0] + TARGET_CYLINDER_RADIUS * np.cos(angles)
y_rim = TARGET_CYLINDER_BASE_CENTER[1] + TARGET_CYLINDER_RADIUS * np.sin(angles)
points_bottom = np.vstack([x_rim, y_rim, np.full_like(x_rim, 0)]).T
points_top = np.vstack([x_rim, y_rim, np.full_like(x_rim, TARGET_CYLINDER_HEIGHT)]).T
TARGET_POINTS = np.vstack([points_bottom, points_top])

# ===== 辅助函数 =====
def calculate_missile_arrival_times():
    """计算各导弹到达目标点的时间"""
    return [np.linalg.norm(m - MISSILE_TARGET_POINT) / MISSILE_SPEED for m in M_INITIAL]

M_ARRIVAL_TIMES = calculate_missile_arrival_times()
MAX_M_ARRIVAL_TIME = max(M_ARRIVAL_TIMES)

def distance_point_to_line_segment(p, a, b):
    """计算点p到线段ab的最短距离"""
    if np.all(a == b): 
        return np.linalg.norm(p - a)
    ap, ab = p - a, b - a
    norm_ab_sq = np.dot(ab, ab)
    if norm_ab_sq == 0: 
        return np.linalg.norm(p - a)
    t = np.dot(ap, ab) / norm_ab_sq
    if t < 0.0: 
        return np.linalg.norm(p - a)
    if t > 1.0: 
        return np.linalg.norm(p - b)
    return np.linalg.norm(p - (a + t * ab))

def get_cover_time(params):
    """
    计算目标被遮蔽的总时间
    :param params: 40个参数 [v0, theta0, t_fly0, rest01, rest02, burst00, burst01, burst02, 
                           v1, theta1, t_fly1, rest11, rest12, burst10, burst11, burst12,
                           ...]
    :return: 目标被遮蔽总时间
    """
    # 解包参数（5架无人机，每架8个参数）
    drone_params = [params[i*8:(i+1)*8] for i in range(5)]
    
    # 组织成get_cover_time需要的格式
    drone_speeds, drone_angles, drone_flying_times = [], [], []
    rest_times, bomb_burst_times = [], []
    
    for param in drone_params:
        v, theta, t_fly, rest1, rest2, burst1, burst2, burst3 = param
        drone_speeds.append(v)
        drone_angles.append(theta)
        drone_flying_times.append(t_fly)
        rest_times.append([rest1, rest2])
        bomb_burst_times.append([burst1, burst2, burst3])
    
    return _get_cover_time([
        drone_speeds, 
        drone_angles, 
        drone_flying_times, 
        rest_times, 
        bomb_burst_times
    ])

def _get_cover_time(particle, output=False):
    """内部函数，计算遮蔽时间"""
    drone_speeds, drone_angles, drone_flying_time, rest_time, bomb_burst_time = particle
    
    # 无人机投弹时刻：5×3
    drone_drop_times = [
        [
            drone_flying_time[i],
            drone_flying_time[i] + rest_time[i][0],
            drone_flying_time[i] + rest_time[i][0] + rest_time[i][1]
        ] for i in range(5)
    ]
    
    # 烟雾弹爆炸时刻：5×3
    bomb_detonation_times = [
        [
            drone_flying_time[i] + bomb_burst_time[i][0],
            drone_flying_time[i] + rest_time[i][0] + bomb_burst_time[i][1],
            drone_flying_time[i] + rest_time[i][0] + rest_time[i][1] + bomb_burst_time[i][2]
        ] for i in range(5)
    ]
    
    # 检查是否所有爆炸均在导弹命中后
    if all(
        det_time >= MAX_M_ARRIVAL_TIME
        for row in bomb_detonation_times for det_time in row
    ):
        return 0
    
    bomb_data = []
    for j in range(5):
        v_x = drone_speeds[j] * np.cos(drone_angles[j])
        v_y = drone_speeds[j] * np.sin(drone_angles[j])
        v_drone = np.array([v_x, v_y, 0])
        
        for i in range(3):
            t_drop = drone_drop_times[j][i]
            t_det = bomb_detonation_times[j][i]
            t_delay = bomb_burst_time[j][i]
            
            p_drop = FY_INITIAL[j] + v_drone * t_drop
            p_detonation = p_drop + v_drone * t_delay + 0.5 * np.array([0, 0, -G]) * t_delay**2
            
            bomb_data.append({
                'drone_id': j,
                'bomb_id': i,
                't_det': t_det,
                't_exp': t_det + CLOUD_EFFECTIVE_DURATION,
                'p_det': p_detonation,
                'p_drop': p_drop
            })
    
    # 导弹方向向量
    m_dir = [(MISSILE_TARGET_POINT - m) / np.linalg.norm(MISSILE_TARGET_POINT - m) for m in M_INITIAL]
    
    # 时间设置
    t_start = min(b['t_det'] for b in bomb_data) if bomb_data else 0
    t_end = MAX_M_ARRIVAL_TIME + CLOUD_EFFECTIVE_DURATION
    dt = 0.2
    
    cover_time = 0.0
    
    # 模拟时间
    for t in np.arange(t_start, t_end, dt):
        p_m_t = [M_INITIAL[k] + m_dir[k] * MISSILE_SPEED * t for k in range(3)]
        
        # 当前活跃的烟雾弹
        active_bombs = [b for b in bomb_data if b['t_det'] <= t <= b['t_exp']]
        if not active_bombs:
            continue
            
        # 检查所有导弹是否都被遮蔽
        all_missiles_concealed = True
        for k in range(3):  # 每枚导弹
            all_target_points_concealed = True
            for p_target in TARGET_POINTS:  # 每个目标点
                point_is_concealed = False
                for active_bomb in active_bombs:  # 每个活跃烟雾弹
                    p_cloud_center = active_bomb['p_det'] - np.array([0, 0, CLOUD_FALL_SPEED * (t - active_bomb['t_det'])])
                    if distance_point_to_line_segment(p_cloud_center, p_m_t[k], p_target) <= CLOUD_RADIUS:
                        point_is_concealed = True
                        break
                
                if not point_is_concealed:
                    all_target_points_concealed = False
                    break
            
            if not all_target_points_concealed:
                all_missiles_concealed = False
                break
        
        if all_missiles_concealed:
            cover_time += dt
    
    return cover_time

# ===== 遗传算法模块 =====
def initialize_population(pop_size, bounds):
    """初始化种群，确保投弹间隔≥1秒"""
    population = np.zeros((pop_size, len(bounds)))
    for i in range(pop_size):
        for j in range(len(bounds)):
            # 对于投弹间隔参数（索引3,4,11,12,19,20,27,28,35,36），确保≥1
            if j in [3,4,11,12,19,20,27,28,35,36]:
                population[i, j] = random.uniform(max(1.0, bounds[j][0]), bounds[j][1])
            else:
                population[i, j] = random.uniform(bounds[j][0], bounds[j][1])
    return population

def roulette_wheel_selection(population, fitness_scores):
    """轮盘赌选择"""
    total_fitness = sum(fitness_scores)
    if total_fitness <= 0:
        return population[np.random.choice(len(population))]
    selection_probs = [f / total_fitness for f in fitness_scores]
    return population[np.random.choice(len(population), p=selection_probs)]

def uniform_crossover(parent1, parent2):
    """均匀交叉"""
    child = parent1.copy()
    for i in range(len(parent1)):
        if random.random() < 0.5:
            child[i] = parent2[i]
    return child

def gaussian_mutation(individual, bounds, mutation_prob, mutation_scale=0.1):
    """高斯变异，确保投弹间隔≥1秒"""
    mutated_individual = individual.copy()
    for i in range(len(individual)):
        if random.random() < mutation_prob:
            range_width = bounds[i][1] - bounds[i][0]
            mutation = np.random.normal(0, range_width * mutation_scale)
            mutated_individual[i] += mutation
            
            # 确保参数在边界内
            mutated_individual[i] = np.clip(mutated_individual[i], bounds[i][0], bounds[i][1])
            
            # 对于投弹间隔参数，确保≥1秒
            if i in [3,4,11,12,19,20,27,28,35,36]:
                mutated_individual[i] = max(1.0, mutated_individual[i])
    
    return mutated_individual

def local_search(individual, bounds):
    """对单个精英个体进行局部搜索"""
    best_neighbor = individual.copy()
    best_fitness = get_cover_time(best_neighbor)

    # 在小邻域内随机扰动30次
    for _ in range(30):
        neighbor = best_neighbor.copy()
        
        # 微调飞行时间、投弹间隔和起爆时间
        for j in range(len(individual)):
            # 只调整时间相关参数（索引2,3,4,5,6,7,10,11,12,13,14,15,...）
            if j in [2,3,4,5,6,7,10,11,12,13,14,15,18,19,20,21,22,23,26,27,28,29,30,31,34,35,36,37,38,39]:
                range_width = bounds[j][1] - bounds[j][0]
                perturbation = np.random.normal(0, range_width * 0.02)
                neighbor[j] += perturbation
                
                # 确保参数在边界内
                neighbor[j] = np.clip(neighbor[j], bounds[j][0], bounds[j][1])
                
                # 对于投弹间隔参数，确保≥1秒
                if j in [3,4,11,12,19,20,27,28,35,36]:
                    neighbor[j] = max(1.0, neighbor[j])
        
        # 检查爆炸时间约束
        valid = True
        for i in range(5):
            t_fly = neighbor[i*8+2]
            rest1 = neighbor[i*8+3]
            rest2 = neighbor[i*8+4]
            burst1 = neighbor[i*8+5]
            burst2 = neighbor[i*8+6]
            burst3 = neighbor[i*8+7]
            
            detonation_times = [
                t_fly + burst1,
                t_fly + rest1 + burst2,
                t_fly + rest1 + rest2 + burst3
            ]
            
            if any(dt > MAX_M_ARRIVAL_TIME for dt in detonation_times):
                valid = False
                break
                
            # 检查投弹间隔是否≥1秒
            if rest1 < 1.0 or rest2 < 1.0:
                valid = False
                break
        
        if not valid:
            continue

        neighbor_fitness = get_cover_time(neighbor)
        if neighbor_fitness > best_fitness:
            best_fitness = neighbor_fitness
            best_neighbor = neighbor
    
    return best_neighbor, best_fitness

# ===== 主程序 =====
if __name__ == '__main__':
    print(f"导弹到达时间: M1={M_ARRIVAL_TIMES[0]:.2f}s, M2={M_ARRIVAL_TIMES[1]:.2f}s, M3={M_ARRIVAL_TIMES[2]:.2f}s")
    print(f"最晚导弹到达时间: {MAX_M_ARRIVAL_TIME:.2f}s")

    # 定义40个决策变量的边界（5架无人机，每架8个参数）
    T_max = MAX_M_ARRIVAL_TIME
    varbound = []
    for _ in range(5):  # 每架无人机
        varbound.append(DRONE_SPEED_BOUNDS)    # 速度
        varbound.append((0, 2*np.pi))          # 角度
        varbound.append((0, T_max))            # 飞行时间
        varbound.append((1.0, T_max))          # 投弹间隔1 (必须≥1秒)
        varbound.append((1.0, T_max))          # 投弹间隔2 (必须≥1秒)
        varbound.append((0, T_max))            # 第一枚弹起爆时间
        varbound.append((0, T_max))            # 第二枚弹起爆时间
        varbound.append((0, T_max))            # 第三枚弹起爆时间
    
    # 配置遗传算法参数
    GA_PARAMS = {
        'num_generations': 150,  # 增加代数
        'population_size': 500,  # 增大种群
        'elit_ratio': 0.05,      # 精英比例
        'crossover_prob': 0.7,
        'mutation_prob': 0.3,
    }
    
    # 阶段一: 初始化
    population = initialize_population(GA_PARAMS['population_size'], varbound)
    best_solution_so_far = None
    best_fitness_so_far = -1

    # 阶段二: 迭代进化
    print("\n--- 使用遗传算法优化5架无人机对抗3枚导弹策略 ---")
    for gen in range(GA_PARAMS['num_generations']):
        # 计算适应度
        fitness_scores = []
        for ind in population:
            # 检查约束：爆炸时间必须小于导弹到达时间，投弹间隔≥1秒
            valid = True
            for i in range(5):
                t_fly = ind[i*8+2]
                rest1 = ind[i*8+3]
                rest2 = ind[i*8+4]
                burst1 = ind[i*8+5]
                burst2 = ind[i*8+6]
                burst3 = ind[i*8+7]
                
                detonation_times = [
                    t_fly + burst1,
                    t_fly + rest1 + burst2,
                    t_fly + rest1 + rest2 + burst3
                ]
                
                if any(dt > MAX_M_ARRIVAL_TIME for dt in detonation_times):
                    valid = False
                    break
                    
                # 检查投弹间隔是否≥1秒
                if rest1 < 1.0 or rest2 < 1.0:
                    valid = False
                    break
            
            if not valid:
                fitness_scores.append(0)  # 无效解
            else:
                fitness_scores.append(get_cover_time(ind))
        
        fitness_scores = np.array(fitness_scores)
        
        # 寻找当前代的精英
        num_elites = int(GA_PARAMS['population_size'] * GA_PARAMS['elit_ratio'])
        elite_indices = np.argsort(fitness_scores)[-num_elites:]
        elites = population[elite_indices]

        # 局部搜索增强
        current_best = np.max(fitness_scores)
        print(f"  第 {gen+1}/{GA_PARAMS['num_generations']} 代, 最佳时长: {current_best:.4f}s. 微调 {num_elites} 个精英...")
        refined_elites = []
        for elite in elites:
            refined_sol, refined_fit = local_search(elite, varbound)
            refined_elites.append(refined_sol)
        
        # 如果找到全局更优解则更新
        current_gen_best_idx = np.argmax(fitness_scores)
        if fitness_scores[current_gen_best_idx] > best_fitness_so_far:
            best_fitness_so_far = fitness_scores[current_gen_best_idx]
            best_solution_so_far = population[current_gen_best_idx].copy()

        # 生成新一代
        new_population = list(refined_elites)  # 精英直接进入下一代
        
        while len(new_population) < GA_PARAMS['population_size']:
            parent1 = roulette_wheel_selection(population, fitness_scores)
            parent2 = roulette_wheel_selection(population, fitness_scores)
            
            child = uniform_crossover(parent1, parent2)
            child = gaussian_mutation(child, varbound, GA_PARAMS['mutation_prob'])
            new_population.append(child)
        
        population = np.array(new_population)

    # 输出最终结果
    print("\n\n==============================================")
    print("      5架无人机烟幕干扰弹投放优化方案")
    print("==============================================")
    print(f"最大有效遮蔽时长 (T_eff): {best_fitness_so_far:.4f} 秒")
    print(f"导弹到达时间: M1={M_ARRIVAL_TIMES[0]:.2f}s, M2={M_ARRIVAL_TIMES[1]:.2f}s, M3={M_ARRIVAL_TIMES[2]:.2f}s")
    
    # 提取最佳参数
    params = best_solution_so_far
    drones = []
    
    # 组织无人机参数
    for i in range(5):
        start_idx = i * 8
        drone_params = {
            'id': f'FY{i+1}',
            'speed': params[start_idx],
            'angle': params[start_idx+1],
            't_fly': params[start_idx+2],
            'rest_time': [params[start_idx+3], params[start_idx+4]],
            'burst_time': [params[start_idx+5], params[start_idx+6], params[start_idx+7]]
        }
        drones.append(drone_params)
    
    # 输出各无人机策略
    for drone in drones:
        angle_deg = np.rad2deg(drone['angle'])
        print(f"\n  --- {drone['id']} 投放策略 ---")
        print(f"    - 飞行速度: {drone['speed']:.2f} m/s")
        print(f"    - 飞行角度: {angle_deg:.2f} 度")
        print(f"    - 初始飞行时间: {drone['t_fly']:.2f} 秒")
        print(f"    - 投弹间隔: {drone['rest_time'][0]:.2f}秒, {drone['rest_time'][1]:.2f}秒")
        print(f"    - 三枚弹起爆时间: {drone['burst_time'][0]:.2f}秒, {drone['burst_time'][1]:.2f}秒, {drone['burst_time'][2]:.2f}秒")
        
        # 计算投弹和爆炸时间
        drop_times = [
            drone['t_fly'],
            drone['t_fly'] + drone['rest_time'][0],
            drone['t_fly'] + drone['rest_time'][0] + drone['rest_time'][1]
        ]
        
        detonation_times = [
            drop_times[0] + drone['burst_time'][0],
            drop_times[1] + drone['burst_time'][1],
            drop_times[2] + drone['burst_time'][2]
        ]
        
        print(f"    - 投弹时间: {drop_times[0]:.2f}秒, {drop_times[1]:.2f}秒, {drop_times[2]:.2f}秒")
        print(f"    - 爆炸时间: {detonation_times[0]:.2f}秒, {detonation_times[1]:.2f}秒, {detonation_times[2]:.2f}秒")
    
    # 验证最终解
    print("\n验证最终解遮蔽效果...")
    final_cover_time = get_cover_time(best_solution_so_far)
    print(f"验证遮蔽时长: {final_cover_time:.4f} 秒")