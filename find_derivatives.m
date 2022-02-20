function second_der = find_derivatives(data, first_tolerence)
tolerence = first_tolerence;

second_der = 0;
% remove zeros from data
zero_ind = (data == 0);
data = data(~zero_ind);

time = 1:length(data);
smooth = csaps(time, data,0.001);

end_time = linspace(length(data)-30,length(data));

data_end = fnval(smooth,end_time);

dy_by_dx = gradient(data_end(:)) ./ gradient(end_time(:));
first_dir = dy_by_dx(length(dy_by_dx));
if abs(first_dir) < tolerence
    dy2 = gradient(dy_by_dx(:))./gradient(end_time(:));
    second_der = dy2(length(dy2));
end
end


