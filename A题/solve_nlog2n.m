function n_max = solve_nlog2n(M)
% 求解满足 n * log2(n) <= M 的最大整数 n
% 输入: M (正实数)
% 输出: n_max (满足条件的最大整数)

    if M < 0
        error('M 必须为非负数');
    elseif M == 0
        n_max = 0;
        return;
    elseif M < 1
        n_max = 1; % 因为 n=1 时 n*log2(n)=0 <= M
        return;
    end

    % 确定二分查找的上下界
    lower = 1;    % 下界（已知满足条件）
    upper = 1;    % 上界
    
    % 快速找到上界：不断加倍直到 n*log2(n) > M
    while upper * log2(upper) <= M
        upper = upper * 2;
    end
    lower = upper / 2; % 此时 lower 满足条件，upper 不满足

    % 二分查找精确解
    while upper - lower > 1
        mid = floor((lower + upper) / 2);
        if mid * log2(mid) <= M
            lower = mid;
        else
            upper = mid;
        end
    end

    % 最终检查 upper 是否满足（由于整数舍入情况）
    if upper * log2(upper) <= M
        n_max = upper;
    else
        n_max = lower;
    end
end