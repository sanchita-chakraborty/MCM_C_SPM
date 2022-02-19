function [prediction, uncertainty] = predict(data, days)
%%%%%%%%%%%%%%%% This function returns a prediction for the next day %
%%%%%%%%%%%%%%%% increase
%%%%%%%%%%%%%%%% as well as a percent uncertainty on it


if ~exist('days','var')
 % third parameter does not exist, so default it to something
  days = 10;
end
uncertain_days = 20; % this is how many days being used for the uncertainty

start = length(data) - days +1; 

% make the prediction

prediction = interpft(data(start:(start+9)),1);
% now turn into a percentage
prediction = (prediction-data(length(data)))/data(length(data));

% find the uncertainty

uncertain_pred = zeros(1,uncertain_days);
start = length(data) - uncertain_days + 1;
for i=1:uncertain_days
    % make prediction for each day
    u_start = start - i;
    pred = interpft(data(u_start:(u_start + uncertain_days)),1);
    day_of = data(u_start + uncertain_days - i-1);
    actual = data(u_start + uncertain_days - i);
    uncertain_pred(i) = abs((actual - pred)/data(u_start + uncertain_days - i -1));
end

% now find overall uncertainty percentage weighted by how recent
% uncertainty = 0;
% denominator = uncertain_days * (uncertain_days + 1)/2;
% for i = 1:uncertain_days
%     uncertainty = uncertainty + (uncertain_days - i+1) * uncertain_pred(i)/denominator;
% end

uncertainty = sum(uncertain_pred)/length(uncertain_pred);
    

