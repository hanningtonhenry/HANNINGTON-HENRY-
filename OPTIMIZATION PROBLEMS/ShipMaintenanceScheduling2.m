
function totalCost = maintCost(x)
    % x = [d1 d2 d3] days
    d1=x(1); d2=x(2); d3=x(3);
    
    fixedCost = 1000;      % per ship
    downtimeDays = 5;      % each maintenance takes 5 days
    costPerDowntime = 100; % per day
    
    baseCost = 3*(fixedCost + costPerDowntime*downtimeDays);
    
    % Penalty if maintenance overlap - need more workers
    penalty = 0;
    if abs(d1-d2) < 7, penalty = penalty + 5000; end
    if abs(d2-d3) < 7, penalty = penalty + 5000; end
    if abs(d1-d3) < 7, penalty = penalty + 5000; end
    
    totalCost = baseCost + penalty;
end

lb = [0 0 0];       % earliest day
ub = [365 365 365]; % latest day
x0 = [30 60 90];    % starting guess for some solvers

% Store time and best cost
names = {'ga','fmincon','particleswarm','patternsearch','surrogateopt','simulannealbnd'};
timeTaken = zeros(1,6);
bestCost = zeros(1,6);

% 1. ga
tic
[x, fval] = ga(@maintCost, 3, [],[],[],[], lb, ub, [], optimoptions('ga','Display','off'));
timeTaken(1)=toc; bestCost(1)=fval; 
fprintf('ga done: Cost=%.1f Time=%.2fs x=[%.1f %.1f %.1f]\n',fval,timeTaken(1),x);

% 2. fmincon
tic
[x, fval] = fmincon(@maintCost, x0, [],[],[],[], lb, ub, [], optimoptions('fmincon','Display','off'));
timeTaken(2)=toc; bestCost(2)=fval;
fprintf('fmincon done: Cost=%.1f Time=%.2fs\n',fval,timeTaken(2));

% 3. particleswarm
tic
[x, fval] = particleswarm(@maintCost, 3, lb, ub, optimoptions('particleswarm','Display','off'));
timeTaken(3)=toc; bestCost(3)=fval;
fprintf('particleswarm done: Cost=%.1f Time=%.2fs\n',fval,timeTaken(3));

% 4. patternsearch
tic
[x, fval] = patternsearch(@maintCost, x0, [],[],[],[], lb, ub, [], optimoptions('patternsearch','Display','off'));
timeTaken(4)=toc; bestCost(4)=fval;
fprintf('patternsearch done: Cost=%.1f Time=%.2fs\n',fval,timeTaken(4));

% 5. surrogateopt - best for expensive problems
tic
[x, fval] = surrogateopt(@maintCost, lb, ub, optimoptions('surrogateopt','Display','off','MaxFunctionEvaluations',200));
timeTaken(5)=toc; bestCost(5)=fval;
fprintf('surrogateopt done: Cost=%.1f Time=%.2fs\n',fval,timeTaken(5));

% 6. simulannealbnd
tic
[x, fval] = simulannealbnd(@maintCost, x0, lb, ub, optimoptions('simulannealbnd','Display','off'));
timeTaken(6)=toc; bestCost(6)=fval;
fprintf('simulannealbnd done: Cost=%.1f Time=%.2fs\n',fval,timeTaken(6));

% GRAPH time taken
figure;
bar(timeTaken)
set(gca,'XTickLabel',names)
ylabel('Time [seconds]')
title('Time taken by each optimizer - Ship Maintenance Problem')
grid on
saveas(gcf,'Ship_Maintenance.png');
disp('Saved Ship_Maintenance.png');

figure;
bar(bestCost)
set(gca,'XTickLabel',names)
ylabel('Best Cost found')
title('Solution quality')
saveas(gcf,'best_cost.png');
disp('Saved best_cost.png');
grid on;