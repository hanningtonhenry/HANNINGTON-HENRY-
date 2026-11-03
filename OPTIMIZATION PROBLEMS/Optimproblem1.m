clear; clc;
lb = [0 0 0];       % start earliest 0h
ub = [48 48 48];    % start latest 48h
x0 = [0 5 10];      % initial guess

names = {'ga','fmincon','particleswarm','patternsearch','surrogateopt','simulannealbnd'};
timeTaken = zeros(1,6);
bestTime = zeros(1,6);
bestX = zeros(6,3);

% 1. ga
tic
[x,fval] = ga(@oilTransferCostPenalty,3,[],[],[],[],lb,ub,[],optimoptions('ga','Display','off'));
timeTaken(1)=toc; bestTime(1)=fval; bestX(1,:)=x;
fprintf('ga done: Time=%.1fh Total=%.2fs x=[%.1f %.1f %.1f]\n',fval,timeTaken(1),x);

% 2. fmincon
tic
[x,fval] = fmincon(@oilTransferCost,x0,[],[],[],[],lb,ub,[],optimoptions('fmincon','Display','off'));
timeTaken(2)=toc; bestTime(2)=fval; bestX(2,:)=x;
fprintf('fmincon done: Time=%.1fh Total=%.2fs\n',fval,timeTaken(2));

% 3. particleswarm
tic
[x,fval] = particleswarm(@oilTransferCostPenalty,3,lb,ub,optimoptions('particleswarm','Display','off'));
timeTaken(3)=toc; bestTime(3)=fval; bestX(3,:)=x;
fprintf('particleswarm done: Time=%.1fh Total=%.2fs\n',fval,timeTaken(3));

% 4. patternsearch
tic
[x,fval] = patternsearch(@oilTransferCost,x0,[],[],[],[],lb,ub,[],optimoptions('patternsearch','Display','off'));
timeTaken(4)=toc; bestTime(4)=fval; bestX(4,:)=x;
fprintf('patternsearch done: Time=%.1fh Total=%.2fs\n',fval,timeTaken(4));

% 5. surrogateopt
tic
[x,fval] = surrogateopt(@oilTransferCostPenalty,lb,ub,optimoptions('surrogateopt','Display','off','MaxFunctionEvaluations',200));
timeTaken(5)=toc; bestTime(5)=fval; bestX(5,:)=x;
fprintf('surrogateopt done: Time=%.1fh Total=%.2fs\n',fval,timeTaken(5));

% 6. simulannealbnd
tic
[x,fval] = simulannealbnd(@oilTransferCostPenalty,x0,lb,ub,optimoptions('simulannealbnd','Display','off'));
timeTaken(6)=toc; bestTime(6)=fval; bestX(6,:)=x;
fprintf('simulannealbnd done: Time=%.1fh Total=%.2fs\n',fval,timeTaken(6));

% GRAPHS
figure;
bar(timeTaken)
set(gca,'XTickLabel',names)
ylabel('Time taken to compute [sec]')
title('PROBLEM 1 - Ship-to-Ship Oil Transfer - Solver Speed')
xtickangle(20)
grid on

figure;
bar(bestTime)
set(gca,'XTickLabel',names)
ylabel('Total transfer time - makespan [hours] - lower is better')
title('Solution quality')
xtickangle(20)
grid on

% Show best schedule found
fprintf('\nBest schedule found (ga):\n');
fprintf('T1 Ship1->Ship2 start at %.1fh, T2 Ship2->Ship3 at %.1fh, T3 Ship1->Ship3 at %.1fh\n',bestX(1,1),bestX(1,2),bestX(1,3));