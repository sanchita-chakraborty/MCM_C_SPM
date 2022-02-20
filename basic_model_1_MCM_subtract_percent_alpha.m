%clf
gamma = 1; % tunable parameter
one_percent = 1;
day_matching = 1;
prediction_affect = 1;
cost_gold = 0.01;
cost_bc = 0.02;

% these are the 'strings' for the different types
cash_str = 1;
gold_str = 2;
bc_str = 3;
days_interp = 25;
start = 100;
% currently ignoring weekends so only doing stuff for
% bchain and gold when both are available
max_time = 1246;


T = readtable('LBMA-GOLD.csv');
dat_gold = table2array(T(1:1256,2));
good = ~isnan(dat_gold);
dat_gold = dat_gold(good);

T2 = readtable('BCHAIN-MKPRU.csv');
dat_bc = table2array(T2(1:1826,2));

% account for missing days/ weekends
h_g = size(T);
h_g = h_g(1);
if day_matching
    dates_gold = table2array(T(:,1));
    dates_bc = table2array(T2(:,1));
    [x, indexes] = intersect(dates_bc, dates_gold);
    new_gold = zeros(size(dates_bc));
    new_gold(indexes) = table2array(T(:,2));
    nan_ind = isnan(new_gold);
    new_gold(nan_ind) = 0;
    dat_gold = new_gold;
    day_matching
end

max_time = length(dat_gold);

time = (1:h_g)';
money_array = zeros(1,h_g);
gold_pred_diff = zeros(1,h_g);
bc_pred_diff = zeros(1,h_g);
uncertainty_gold = zeros(1,h_g);
uncertainty_bc = zeros(1,h_g);

% starting conditions
total_money = 1000;
cash = 1000;
gold = 0;
bc = 0;
pred = [0 0 0];
gold_uncert = 0;
bc_uncert = 0;

for today = start:max_time
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
    
    % check if skipping weekend
    num_ahead = 1;
    if(today + 1 <= max_time)
        if (dat_gold(today+1) == 0)
            num_ahead = 2;
            if (today + 2 <= max_time)
                if (dat_gold(today+2) == 0)
                    num_ahead = 3;
                end
            end
        end
    end
        
    % make predictions for gold and bc
    % note that since the zero days are removed from gold we always only
    % look ahead 1 day with gold
    [gold_pred, gold_uncert] = predict(dat_gold(1:today),days_interp,1,10);
    [bc_pred, bc_uncert] = predict(dat_bc(1:today),days_interp, num_ahead,2);
    
    % account for alpha = 0.01 in predictions
    gold_pred = gold_pred + prediction_affect * ( gold_old * dat_gold(today))/total_money;
    bc_pred = bc_pred + prediction_affect * (bc_old * dat_bc(today))/total_money;
    cash_pred = 0% - prediction_affect * (total_money - 0)/total_money;
    
    
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
        total_delta = cost_gold*abs(gold-gold_old)*dat_gold(today) + cost_bc * abs(bc-bc_old) * dat_bc(today);
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
    
    % if it is a day gold isn't sold then don't buy anything
    
    if (dat_gold(today) == 0)
        gold = gold_old;
        cash = cash_old;
        bc = bc_old;
    end
    money_array(today) = total_money;
    if (dat_gold(today) == 0)
        money_array(today) = money_array(today - 1);
        bc_pred_diff(today) = bc_pred_diff(today-1);
        gold_pred_diff(today) = gold_pred_diff(today-1);
        uncertainty_gold(today) = uncertainty_gold(today-1);
        uncertainty_bc(today) = uncertainty_bc(today-1);
    end
end
end_money = total_money
max_money = max(money_array)
min_money = min(money_array(start+1:length(money_array)))
figure(1)
hold on
plot(money_array(start-1:length(money_array)))
legend()


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
