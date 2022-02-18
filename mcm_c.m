clear all; close all;

time = (1:1256)';

T = readtable('LBMA-GOLD.csv');
dat_gold = table2array(T(1:1256,2));

T2 = readtable('BCHAIN-MKPRU.csv');
dat_bc = table2array(T2(1:1826,2));

query_gold = [11:20];
limtime = 1:30;
limtime2 = 11:30

F1 = interp1(time(1:10),dat_gold(1:10), 'spline');
%extrapgold = interp1(limtime,F1,query_gold,'linear', 'extrap');
extrapgold = interpft(dat_gold(1:10),20)
plot(limtime, dat_gold(1:30),'o')
hold all
plot(limtime2, extrapgold, 'r-')
grid on
