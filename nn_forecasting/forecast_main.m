clear;
clc;

%Read pre-processed data
data=read_mixed_csv('R_output_full_interpolated_newdata.csv', ',');

%Extract datetime and power
time=datetime(data(2:end,1));
power=str2double(data(2:end,2));

stime=data(2:end,1);
spower=data(2:end,2);

m = length(time);

%Converting to date vector for neural network inputs
time_vec = datevec(time);
list_dates = [];

%Day of the week
day_num = weekday(time);
list_holidays = find_holidays(1000); %Energy threshold of 1000
list_holidays = sort(list_holidays);


%We get the list of all dates and set the time to 00:00:00
for i=1:m
    
    time_vec(i, 4) = 0;
    time_vec(i, 5) = 0;
    time_vec(i, 6) = 0;
    list_dates = [list_dates; datetime(time_vec(i, :))];
end

%removing duplicates so that one date only appears once
list_dates = unique(list_dates);
list_working = setdiff(list_dates, list_holidays);

%Splitting into training and testing data 60-40
train_len_hol = round(60*length(list_holidays)/100);
train_len_work = round(60*length(list_working)/100);

%Picking 60% of the dates randomly
train_hol = randsample(list_holidays, train_len_hol);
train_work = randsample(list_working, train_len_work);

%Storing the other 40% 
test_hol = setdiff(list_holidays, train_hol);
test_work = setdiff(list_working, train_work);

train_work = sort(train_work);
train_hol = sort(train_hol);
test_work = sort(test_work);
test_hol = sort(test_hol);

%For the other model, we use all but one data for training
train_work_single = randsample(list_working, length(list_working)-1);
train_hol_single = randsample(list_holidays, length(list_holidays)-1);

test_work_single = setdiff(list_working, train_work_single);
test_hol_single = setdiff(list_holidays, train_hol_single);

train_work_single = sort(train_work_single);
train_hol_single = sort(train_hol_single);
test_work_single = sort(test_work_single);
test_hol_single = sort(test_hol_single);

%Creating two lists of datetimes that contain only working and holidays
%respectively

htime = [];
j = 1;

for i=1:length(list_holidays)
    
    k = datevec(list_holidays(i));
    k = [k(1) k(2) k(3)];

    for ii=1:m

        ktime = datevec(time(ii));
        ktime = [ktime(1) ktime(2) ktime(3)];
        %Checking equality
        if sum(k==ktime)==3 %year, month and time are equal

            htime = [htime; time(ii)];   

        end
    end
end

wtime = setdiff(time, htime);

%For 60 40 forecast

[xtrain_w, ytrain_w] = extract_time_power(time, power, wtime, train_work);
[xtest_w, ytest_w] = extract_time_power(time, power, wtime, test_work);
[xtrain_h, ytrain_h] = extract_time_power(time, power, htime, train_hol);
[xtest_h, ytest_h] = extract_time_power(time, power, htime, test_hol);

%For single day forecast
% [xtrain_w_single, ytrain_w_single] = extract_time_power(time, power, wtime, train_work_single);
% [xtest_w_single, ytest_w_single] = extract_time_power(time, power, wtime, test_work_single);
% [xtrain_h_single, ytrain_h_single] = extract_time_power(time, power, htime, train_hol_single);
% [xtest_h_single, ytest_h_single] = extract_time_power(time, power, htime, test_hol_single);

%Generating feature arrays
xtrain_w = gen_features(xtrain_w);
xtest_w = gen_features(xtest_w);
xtrain_h = gen_features(xtrain_h);
xtest_h = gen_features(xtest_h);

% xtrain_w_single = gen_features(xtrain_w_single);
% xtest_w_single = gen_features(xtest_w_single);
% xtrain_h_single = gen_features(xtrain_h_single);
% xtest_h_single = gen_features(xtest_h_single);
 
%Clearing all other data
% clear data day_num htime i ii j k ktime list_dates list_holidays list_working m power spower stime test_hol test_hol_single test_work test_work_single time time_vec train_hol train_hol_single train_len_hol train_len_work train_work train_work_single wtime 

%Training neural network

net = nn_train(xtrain_w, ytrain_w);
yf = net(xtest_w')';
disp(calculate_mape(ytest_w, yf));








