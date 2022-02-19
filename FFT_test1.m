
clear all; close all;
max_time = 1256
time = (1:1256)';

T = readtable('LBMA-GOLD.csv');
dat_gold = table2array(T(1:1256,2));

T2 = readtable('BCHAIN-MKPRU.csv');
dat_bc = table2array(T2(1:1826,2));

plot(time, dat_gold);

hold on
query_gold = [11:20];
limtime = 1:30;
limtime2 = 11:30

for start = 1:(max_time-10)

    F1 = interp1(time(start:(start+10)),dat_gold(start:(start+10)), 'spline');
    %extrapgold = interp1(limtime,F1,query_gold,'linear', 'extrap');
    extrapgold = interpft(dat_gold(start:(start+10)),5)
    plot(time(start+10+1:(start+10+5)), extrapgold,'r-')
end
grid on
