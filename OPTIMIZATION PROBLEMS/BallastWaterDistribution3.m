prob = optimproblem("Description","Ballast Water distribution")
show(prob)

function [J, c, ceq] = ballast_problem(x)
    % --- STEP 2: DEFINE VARIABLES ---
    % x(1)=Tank1, x(2)=Tank2, x(3)=Tank3 [m3]
    V1 = x(1); V2 = x(2); V3 = x(3);
    
    % Tank data
    cap = [500, 600, 400]; % max capacity
    y_pos = [-5, 0, 5]; % transverse position for stability [m]
    l_pos = [20, 0, -15]; % longitudinal position for trim [m]
    
    % STEP 3: OBJECTIVE - minimize pumping energy
    % Energy ~ V^2 / pump efficiency + head loss
    % Simple model: Energy = 0.1*V^2
    pumping_energy = 0.1*(V1^2 + V2^2 + V3^2);
    % Add operating time: time = max(Vi / pump_rate)
    pump_rate = 100; % m3/h
    pumping_time = max(x) / pump_rate;
    
    J = pumping_energy + 10*pumping_time; % minimize both
    
    % --- STEP 4: DEFINE CONSTRAINTS ---
    % c <= 0 feasible, ceq = 0 feasible
    c = [];
    % 1. Tank capacity: Vi <= capi and Vi >=0 handled by bounds
    % 2. Stability: GM must be >= 0.5m - simplified as moment of inertia
    % We want transverse moment ~0 for zero list
    list_moment = V1*y_pos(1) + V2*y_pos(2) + V3*y_pos(3);
    c(1) = abs(list_moment) - 50; % |list| <= 50 m4
    
    % Trim moment should be small
    trim_moment = V1*l_pos(1) + V2*l_pos(2) + V3*l_pos(3);
    c(2) = abs(trim_moment) - 200; % |trim| <= 200
    
    % ceq: total ballast must be 1000 m3
    ceq = (V1+V2+V3) - 1000;
end


% CREATE OPTIMIZATION PROBLEM
lb = [0 0 0];
ub = [500 600 400]; % tank capacities
x0 = [300 300 400]; % initial guess

names = {'ga','fmincon','particleswarm','patternsearch','surrogateopt','simulannealbnd'};
times = zeros(1,6); fvals = zeros(1,6); x_opt = zeros(6,3);

% STEP 5: SOLVE WITH 6 OPTIMIZERS

% 1. ga
tic
[x_opt(1,:), fvals(1)] = ga(@(x) ballast_problem(x),3,[],[],[],[],lb,ub,@(x) deal_constr(x),optimoptions('ga','Display','off','MaxGenerations',50));
times(1)=toc;

% 2. fmincon
tic
[x_opt(2,:), fvals(2)] = fmincon(@(x) ballast_problem(x),x0,[],[],[],[],lb,ub,@(x) deal_constr(x),optimoptions('fmincon','Display','off','Algorithm','sqp'));
times(2)=toc;

% 3. particleswarm
tic
[x_opt(3,:), fvals(3)] = particleswarm(@(x) ballast_problem(x),3,lb,ub,optimoptions('particleswarm','Display','off','SwarmSize',40));
times(3)=toc;

% 4. patternsearch
tic
[x_opt(4,:), fvals(4)] = patternsearch(@(x) ballast_problem(x),x0,[],[],[],[],lb,ub,@(x) deal_constr(x),optimoptions('patternsearch','Display','off'));
times(4)=toc;

% 5. surrogateopt - needs penalty for constraints
tic
[x_opt(5,:), fvals(5)] = surrogateopt(@(x) ballast_penalty(x),lb,ub,optimoptions('surrogateopt','Display','off','MaxFunctionEvaluations',100));
times(5)=toc;

% 6. simulannealbnd
tic
[x_opt(6,:), fvals(6)] = simulannealbnd(@(x) ballast_penalty(x),x0,lb,ub,optimoptions('simulannealbnd','Display','off'));
times(6)=toc;

T = table(names', times', fvals', x_opt, 'VariableNames',{'Optimizer','Time_s','Energy','Ballast_V1_V2_V3'});
disp(T);

% Graph 1: Time comparison 
figure
b = bar(times)
set(gca,'XTickLabel',names); xtickangle(30)
ylabel('Time (seconds)')
title('Ballast Distribution - Time taken by optimizer')
legend('Computation Time')
saveas(gcf,'comparison.png');
disp('Saved comparison.png');
grid on

% Graph 2: Ballast distribution
figure; hold on
[~, best_idx] = min(fvals);
best = x_opt(best_idx,:);
bar(best)
ylabel('Water Volume [m3]')
xlabel('Tank')
set(gca,'XTickLabel',{'Tank1 (500)','Tank2 (600)','Tank3 (400)'})
title(['Best Ballast by ' names{best_idx} ' - Energy: ' num2str(fvals(best_idx),'%.1f')])
legend('Ballast Volume')
saveas(gcf,'best_ballast.png');
disp('Saved best_ballast.png');
grid on

% Helper functions for constraints
function [c, ceq] = deal_constr(x)
    [~, c, ceq] = ballast_problem(x);
end

function J = ballast_penalty(x)
    [J0, c, ceq] = ballast_problem(x);
    penalty = 1000*sum(max(0,c).^2) + 1000*ceq^2;
    J = J0 + penalty;
end