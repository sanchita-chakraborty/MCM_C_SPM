clf
gamma = 1; % tunable parameter
one_percent = 1;

% these are the 'strings' for the different types
cash_str = 1;
gold_str = 2;
bc_str = 3;
days_interp = 25;
start = 100;
% currently ignoring weekends so only doing stuff for
% bchain and gold when both are available
max_time = 1246;
time = (1:max_time)';
money_array = zeros(1,max_time);
gold_pred_diff = zeros(1,max_time);
bc_pred_diff = zeros(1,max_time);
uncertainty_gold = zeros(1,max_time);
uncertainty_bc = zeros(1,max_time);

T = readtable('LBMA-GOLD.csv');
dat_gold = table2array(T(1:1256,2));
good = ~isnan(dat_gold);
dat_gold = dat_gold(good);

T2 = readtable('BCHAIN-MKPRU.csv');
dat_bc = table2array(T2(1:1826,2));

% starting conditions
total_money = 1000;
cash = 1000;
gold = 0;
bc = 0;
pred = [0 0 0];
gold_uncert = 0;
bc_uncert = 0;

for today = start:start+1
    total_money = cash + gold * dat_gold(today) + bc * dat_bc(today);
    gold_old = gold;
    cash_old = cash;
    bc_old = bc;
    gold = 0;
    cash = 0;
    bc = 0;
    old_pred = pred;
    yesterday = today-1;
    today_pred = [0, (dat_gold(today)-dat_gold(yesterday))/dat_gold(yesterday), (dat_bc(today)-dat_bc(yesterday))/dat_bc(yesterday)];
    bc_pred_diff(today) = old_pred(3) - today_pred(2);
    gold_pred_diff(today) = old_pred(2) - today_pred(2);
    uncertainty_gold(today) = gold_uncert;
    uncertainty_bc(today) = bc_uncert;
    
    % make predictions for gold and bc
    
    [gold_pred, gold_uncert] = predict(dat_gold(1:today),days_interp);
    [bc_pred, bc_uncert] = predict(dat_bc(1:today),days_interp);
    
    % account for alpha = 0.01 in predictions
    gold_pred = gold_pred - 0.01 * (total_money - gold_old * dat_gold(today))/total_money;
    bc_pred = bc_pred - 0.01 * (total_money - bc_old * dat_bc(today))/total_money;
    
    
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
    amt_pred_best = min(1,gamma * diff_pred/(diff_pred + diff_worst));
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
        gold = total_money * amt_2/ dat_gold(today);
    end
    if ((bc_str == ind_pred_2) && (cash_str ~= ind_pred_best))
        bc = total_money * amt_2/dat_bc(today);
    end
    if (cash_str == ind_pred_2 && cash_str ~= ind_pred_best)
        cash = total_money * amt_2;
    end
    
    if (one_percent)
        % account for 1% loss from buying / selling
        total_delta = 0.01 * (abs(gold-gold_old)*dat_gold(today) + abs(bc-bc_old) * dat_bc(today));
        % remove this from second best
        if (gold_str == ind_pred_2 && cash_str ~= ind_pred_best)
            gold = gold - total_delta/dat_gold(today);
        end
        if (bc_str == ind_pred_2 && cash_str ~= ind_pred_best)
            bc = bc -total_delta /dat_bc(today);
        end
        if (cash_str == ind_pred_2 && cash_str ~= ind_pred_best)
            cash = cash - total_delta;
        end

        if (cash_str == ind_pred_best)
            cash = cash - total_delta;
        end
    end

    
    money_array(today) = total_money;
    
end
end_money = total_money
max_money = max(money_array)
min_money = min(money_array(start+1:max_time))
figure(1)
hold on
plot(money_array(start-1:max_time))
legend()
% 
% 
% figure(2)
% clf
% hold on
% plot(gold_pred_diff)
% plot(uncertainty_gold)
% legend('gold prediction difference', 'gold uncertainty')
% 
% figure(3)
% clf
% hold on
% plot(bc_pred_diff)
% 
% plot(uncertainty_bc)
% legend('bc prediction difference', 'bc uncertainty')

% figure(4)
% clf
% hold on
% plot(uncertainty_gold)
% plot(uncertainty_bc)
% 
% legend('gold uncertainty', 'bc uncertainty')
% 
% 
% 
% 
