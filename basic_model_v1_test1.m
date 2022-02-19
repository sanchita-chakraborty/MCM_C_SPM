clear all;
gamma = 1; % tunable parameter

% these are the 'strings' for the different types
cash_str = 1;
gold_str = 2;
bc_str = 3;

% currently ignoring weekends so only doing stuff for
% bchain and gold when both are available
max_time = 1256;
time = (1:max_time)';
money_array = zeros(1,max_time);

T = readtable('LBMA-GOLD.csv');
dat_gold = table2array(T(1:1256,2));

T2 = readtable('BCHAIN-MKPRU.csv');
dat_bc = table2array(T2(1:1826,2));

% starting conditions
total_money = 1000;
cash = 1000;
gold = 0;
bc = 0;

for today = 30:max_time
    total_money = cash + gold * dat_gold(today) + bc * dat_bc(today);
    
    % make predictions for gold and bc
    
    start = today-10 + 1;
    
    [gold_pred, gold_uncert] = predict(dat_gold(1:today),10);
    [bc_pred, bc_uncert] = predict(dat_bc(1:today),10);
    
    
    %now determine which are the best!
    pred = [0; gold_pred; bc_pred];
    worst = [0; gold_pred - gold_uncert; bc_pred-bc_uncert];
    
    [pred_best, ind_pred_best] = max(pred);
    [pred_worst, ind_pred_worst] = min(pred);
    ind_pred_2 = 6 - ind_pred_best - ind_pred_worst;
    [worst_best, ind_worst_best] = max(worst);
    
    % calculate how much to buy
    diff_pred = pred(ind_pred_best) - pred(ind_worst_best);
    diff_worst = worst(ind_worst_best) - worst(ind_pred_best);
    amt_pred_best = gamma * diff_pred/(diff_pred + diff_worst);
    amt_2 = 1 - amt_pred_best;
    % handle case that both predict the same thing
    if (ind_pred_best == ind_worst_best)
        amt_pred_best = 0.8;
        amt_2 = 0.2;
    end
    
    % make sure nothing gets more than 80% unless cash
    if ((amt_pred_best > 0.8) && (pred_best ~= 0))
        amt_pred_best = 0.8;
        amt_2 = 0.2;
    end
    if ((amt_2 > 0.8) && (ind_pred_2 ~= 0))
        amt_pred_best = 0.2;
        amt_2 = 0.8;
    end
    
    % now make sale
    
    if (gold_str == ind_pred_best)
        gold = amt_pred_best * total_money/ dat_gold(today);
    end
    if (bc_str == ind_pred_best)
        bc = amt_pred_best * total_money/dat_bc(today);
    end
    if (cash_str == ind_pred_best)
        cash = total_money;
    end
    
    
    if (gold_str == ind_pred_2 && cash_str ~= ind_pred_best)
        gold = amt_pred_best * amt_2/ dat_gold(today);
    end
    if (bc_str == ind_pred_2 && cash_str ~= ind_pred_best)
        bc = amt_pred_best * amt_2/dat_bc(today);
    end
    if (cash_str == ind_pred_2 && cash_str ~= ind_pred_best)
        cash = total_money * amt_2;
    end
    
    money_array(today) = total_money;
    plot(money_array(31:max_time))
    today
end






