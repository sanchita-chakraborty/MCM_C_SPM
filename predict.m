function [prediction, uncertainty] = predict(data, days, num_ahead, double)
%%%%%%%%%%%%%%%% This function returns a prediction for the next day %
%%%%%%%%%%%%%%%% increase
%%%%%%%%%%%%%%%% as well as a percent uncertainty on it


if ~exist('days','var')
 % third parameter does not exist, so default it to something
  days = 10;
end

if ~exist('num_ahead','var')
 % third parameter does not exist, so default it to something
  num_ahead = 1;
end

if ~exist('double','var')
 % third parameter does not exist, so default it to something
  days = 1;
end

% remove zeros from data
zero_ind = (data == 0);
data = data(~zero_ind);

uncertain_days = 20; % this is how many days being used for the uncertainty

start = length(data) - days +1; 

% make the prediction

prediction = interpft(data(start:(start+days -1)),num_ahead);
prediction = prediction(length(prediction));
% now turn into a percentage
prediction = (prediction-data(length(data)))/data(length(data));

% find the uncertainty

uncertain_pred = zeros(1,uncertain_days);
start = length(data) - uncertain_days+1 - (num_ahead-1); 
for i=1:uncertain_days
    % make prediction for each day
    u_start = start - i;
    pred = interpft(data(u_start:(u_start + uncertain_days)),num_ahead);
    pred = pred(length(pred));
    pred = (pred - data(u_start + uncertain_days-1))/data(u_start + uncertain_days-1);
%     day_of = data(u_start + uncertain_days - i-1);
%     day_of = (day_of -  data(u_start + uncertain_days)/data(u_start + uncertain_days);
    actual = data(u_start + uncertain_days);
    actual = (actual -  data(u_start + uncertain_days-1))/data(u_start + uncertain_days-2);
    uncertain_pred(i) = abs(actual - pred);
end

% now find overall uncertainty percentage weighted by how recent
uncertainty = 0;
denominator = uncertain_days * (uncertain_days + 1)/2;
for i = 1:uncertain_days
    uncertainty = uncertainty + (uncertain_days - i+1) * uncertain_pred(i)/denominator;
end
uncertainty = uncertainty *double;

% uncertainty = sum(uncertain_pred)/length(uncertain_pred);
    

