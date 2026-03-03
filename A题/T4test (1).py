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
    np.array([6000, -3000, 700])
]
M1_START = np.array([20000, 0, 2000])
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
def calculate_m1_arrival_time():
    """计算导弹到达目标点的时间"""
    distance = np.linalg.norm(MISSILE_TARGET_POINT - M1_START)
    return distance / MISSILE_SPEED

M1_ARRIVAL_TIME = calculate_m1_arrival_time()

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
    :param params: 12个参数 [v1, angle1, t_fly1, t_burst1, v2, angle2, t_fly2, t_burst2, v3, angle3, t_fly3, t_burst3]
    :return: 目标被遮蔽总时间
    """
    # 解包参数
    v1, angle1, t_fly1, t_burst1, v2, angle2, t_fly2, t_burst2, v3, angle3, t_fly3, t_burst3 = params
    drone_speeds = [v1, v2, v3]
    drone_angles = [angle1, angle2, angle3]
    drone_flying_times = [t_fly1, t_fly2, t_fly3]
    bomb_burst_times = [t_burst1, t_burst2, t_burst3]
    
    # 计算烟雾弹爆炸时间
    bomb_detonation_times = [
        drone_flying_times[i] + bomb_burst_times[i] 
        for i in range(3)
    ]
    
    # 检查是否所有烟雾弹都在导弹到达后爆炸（无效解）
    if all(t >= M1_ARRIVAL_TIME for t in bomb_detonation_times):
        return 0

    # 计算导弹方向向量
    missile_direction = (MISSILE_TARGET_POINT - M1_START) / np.linalg.norm(MISSILE_TARGET_POINT - M1_START)
    
    # 计算烟雾弹投放和爆炸位置
    bomb_data = []
    for i in range(3):
        v_x = drone_speeds[i] * np.cos(drone_angles[i])
        v_y = drone_speeds[i] * np.sin(drone_angles[i])
        v_drone = np.array([v_x, v_y, 0])
        
        # 投放位置
        drop_pos = FY_INITIAL[i] + v_drone * drone_flying_times[i]
        
        # 爆炸位置（考虑重力影响）
        detonation_pos = drop_pos + v_drone * bomb_burst_times[i] + 0.5 * np.array([0, 0, -G]) * bomb_burst_times[i]**2
        
        bomb_data.append({
            'detonation_time': drone_flying_times[i] + bomb_burst_times[i],
            'expiry_time': drone_flying_times[i] + bomb_burst_times[i] + CLOUD_EFFECTIVE_DURATION,
            'detonation_pos': detonation_pos
        })

    # 时间步长和总遮蔽时间
    delta_t = 0.2
    cover_time = 0
    t_start = min(b['detonation_time'] for b in bomb_data)
    t_end = M1_ARRIVAL_TIME + 20  # 导弹到达后继续观察20秒

    # 模拟导弹飞行过程
    for t in np.arange(t_start, t_end, delta_t):
        missile_pos = M1_START + missile_direction * MISSILE_SPEED * t
        
        # 检查当前活跃的烟雾弹
        active_bombs = [
            bomb for bomb in bomb_data 
            if bomb['detonation_time'] <= t <= bomb['expiry_time']
        ]
        
        if not active_bombs:
            continue
            
        # 检查所有目标点是否被遮蔽
        all_points_covered = True
        for point in TARGET_POINTS:
            point_covered = False
            
            # 检查该点是否被任何活跃烟雾弹遮蔽
            for bomb in active_bombs:
                # 计算烟雾当前位置（考虑下落）
                cloud_center = bomb['detonation_pos'] - np.array([0, 0, CLOUD_FALL_SPEED * (t - bomb['detonation_time'])])
                
                # 计算点到导弹-目标连线的距离
                distance = distance_point_to_line_segment(cloud_center, missile_pos, point)
                
                if distance <= CLOUD_RADIUS:
                    point_covered = True
                    break
                    
            if not point_covered:
                all_points_covered = False
                break
                
        # 如果所有目标点都被遮蔽，增加遮蔽时间
        if all_points_covered:
            cover_time += delta_t
    
    return cover_time

# ===== 遗传算法模块 =====
def initialize_population(pop_size, bounds):
    """初始化种群"""
    population = np.zeros((pop_size, len(bounds)))
    for i in range(pop_size):
        for j in range(len(bounds)):
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
    """高斯变异"""
    mutated_individual = individual.copy()
    for i in range(len(individual)):
        if random.random() < mutation_prob:
            range_width = bounds[i][1] - bounds[i][0]
            mutation = np.random.normal(0, range_width * mutation_scale)
            mutated_individual[i] += mutation
            # 确保仍在边界内
            mutated_individual[i] = np.clip(mutated_individual[i], bounds[i][0], bounds[i][1])
    return mutated_individual

def local_search(individual, bounds):
    """对单个精英个体进行局部搜索"""
    best_neighbor = individual.copy()
    best_fitness = get_cover_time(best_neighbor)

    # 在小邻域内随机扰动20次
    for _ in range(20):
        neighbor = best_neighbor.copy()
        
        # 微调飞行时间和起爆时间
        for j in [2, 3, 6, 7, 10, 11]:  # 索引: t_fly1, t_burst1, t_fly2, t_burst2, t_fly3, t_burst3
            range_width = bounds[j][1] - bounds[j][0]
            perturbation = np.random.normal(0, range_width * 0.02)  # 更小的扰动
            neighbor[j] += perturbation
        
        # 确保所有参数在边界内
        for d in range(len(neighbor)):
            neighbor[d] = np.clip(neighbor[d], bounds[d][0], bounds[d][1])
        
        # 检查约束：爆炸时间必须小于导弹到达时间
        detonation_times = [
            neighbor[2] + neighbor[3],  # t_fly1 + t_burst1
            neighbor[6] + neighbor[7],  # t_fly2 + t_burst2
            neighbor[10] + neighbor[11] # t_fly3 + t_burst3
        ]
        if any(dt > M1_ARRIVAL_TIME for dt in detonation_times):
            continue

        neighbor_fitness = get_cover_time(neighbor)
        if neighbor_fitness > best_fitness:
            best_fitness = neighbor_fitness
            best_neighbor = neighbor
    
    return best_neighbor, best_fitness

# ===== 主程序 =====
if __name__ == '__main__':
    print(f"导弹M1将于 t = {M1_ARRIVAL_TIME:.2f} 秒后到达其目标 (0,0,0)。")

    # 定义12个决策变量的边界（每架无人机4个参数）
    varbound = [
        DRONE_SPEED_BOUNDS, (0, 2*np.pi), (0, M1_ARRIVAL_TIME), (0, M1_ARRIVAL_TIME),   # FY1
        DRONE_SPEED_BOUNDS, (0, 2*np.pi), (0, M1_ARRIVAL_TIME), (0, M1_ARRIVAL_TIME),   # FY2
        DRONE_SPEED_BOUNDS, (0, 2*np.pi), (0, M1_ARRIVAL_TIME), (0, M1_ARRIVAL_TIME)    # FY3
    ]
    
    # 配置遗传算法参数
    GA_PARAMS = {
        'num_generations': 500,
        'population_size': 300,  # 增加种群大小以适应更多变量
        'elit_ratio': 0.05,       # 精英比例
        'crossover_prob': 0.7,
        'mutation_prob': 0.3,
    }
    
    # 阶段一: 初始化
    population = initialize_population(GA_PARAMS['population_size'], varbound)
    best_solution_so_far = None
    best_fitness_so_far = -1

    # 阶段二: 迭代进化
    print("\n--- 使用自定义遗传算法优化三架无人机投放策略 ---")
    for gen in range(GA_PARAMS['num_generations']):
        # 计算适应度
        fitness_scores = []
        for ind in population:
            # 检查约束：爆炸时间必须小于导弹到达时间
            detonation_times = [
                ind[2] + ind[3],  # FY1: t_fly + t_burst
                ind[6] + ind[7],  # FY2
                ind[10] + ind[11] # FY3
            ]
            if any(dt > M1_ARRIVAL_TIME for dt in detonation_times):
                fitness_scores.append(0)  # 无效解
            else:
                fitness_scores.append(get_cover_time(ind))
        
        fitness_scores = np.array(fitness_scores)
        
        # 寻找当前代的精英
        num_elites = int(GA_PARAMS['population_size'] * GA_PARAMS['elit_ratio'])
        elite_indices = np.argsort(fitness_scores)[-num_elites:]
        elites = population[elite_indices]

        # 局部搜索增强
        print(f"  第 {gen+1}/{GA_PARAMS['num_generations']} 代, 最佳时长: {np.max(fitness_scores):.4f}s. 微调 {num_elites} 个精英...")
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
    print("      三架无人机烟幕干扰弹投放优化方案")
    print("==============================================")
    print(f"最大有效遮蔽时长 (T_eff): {best_fitness_so_far:.4f} 秒")
    print(f"导弹到达时间: {M1_ARRIVAL_TIME:.2f} 秒")
    
    # 提取最佳参数
    params = best_solution_so_far
    drones = [
        {'id': 'FY1', 'speed': params[0], 'angle': params[1], 't_fly': params[2], 't_burst': params[3]},
        {'id': 'FY2', 'speed': params[4], 'angle': params[5], 't_fly': params[6], 't_burst': params[7]},
        {'id': 'FY3', 'speed': params[8], 'angle': params[9], 't_fly': params[10], 't_burst': params[11]}
    ]
    
    # 输出各无人机策略
    for drone in drones:
        angle_deg = np.rad2deg(drone['angle'])
        detonation_time = drone['t_fly'] + drone['t_burst']
        print(f"\n  --- {drone['id']} 投放策略 ---")
        print(f"    - 飞行速度: {drone['speed']:.2f} m/s")
        print(f"    - 飞行角度: {angle_deg:.2f} 度")
        print(f"    - 飞行时间: {drone['t_fly']:.2f} 秒")
        print(f"    - 起爆时间: {drone['t_burst']:.2f} 秒")
        print(f"    - 爆炸时间: {detonation_time:.2f} 秒")
        print(f"    - 爆炸位置: {FY_INITIAL[['FY1','FY2','FY3'].index(drone['id'])] + drone['speed']*np.array([np.cos(drone['angle']), np.sin(drone['angle']), 0])*drone['t_fly']}")
    
    # 验证最终解
    print("\n验证最终解遮蔽效果...")
    final_cover_time = get_cover_time(best_solution_so_far)
    print(f"验证遮蔽时长: {final_cover_time:.4f} 秒")