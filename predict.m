function [prediction, uncertainty] = predict(data, days)
%%%%%%%%%%%%%%%% This function returns a prediction for the next day %
%%%%%%%%%%%%%%%% increase
%%%%%%%%%%%%%%%% as well as a percent uncertainty on it


if ~exist('days','var')
 % third parameter does not exist, so default it to something
  days = 10;
end
uncertain_days = 10; % this is how many days being used for the uncertainty

start = length(data) - days +1; 

% make the prediction

prediction = interpft(data(start:(start+9)),1);
% now turn into a percentage
prediction = (prediction-data(length(data)))/data(length(data));

% find the uncertainty

uncertain_pred = zeros(uncertain_days);
for i=1:uncertain_days
    % make prediction for each day
    u_start = start - i;
    pred = interpft(data(u_start:(u_start + 10)),1);
    actual = data(u_start + 10 - i);
    uncertain_pred(i) = abs((actual - pred)/actual);
end

% now find overall uncertainty percentage weighted by how recent
uncertainty = 0;
denominator = uncertain_days * (uncertain_days + 1)/2;
for i = 1:uncertain_days
    uncertainty = uncertainty + i * uncertain_pred(i)/denominator
end

