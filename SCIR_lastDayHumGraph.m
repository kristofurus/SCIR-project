% channel IDs and keys
sensorChannelID = 1883175;
sensorChannelReadKey = '77REZTLTX4JJ12XN'; 
humidityFieldID = [2 5 7]; 

internetChannel = 1890915;
internetChannelReadKey = 'CT8EQRAQBZGWLM2L';

NUM_OF_HOURS = 25;
NUM_OF_SENSORS = size(humidityFieldID, 2);

% get last 24 values from internet data
[internet_hum, internet_times] = thingSpeakRead(internetChannel, 'Fields', 2, 'NumMinutes', NUM_OF_HOURS*60, 'ReadKey', internetChannelReadKey);
last_hour = hour(internet_times(end));

% current time
current_time = datetime('now');
additional_minutes = round(minutes(current_time-internet_times(end)));

% get last whole 24 hours
[hum, time] = thingSpeakRead(sensorChannelID, 'Fields', humidityFieldID, 'NumMinutes', NUM_OF_HOURS*60+additional_minutes, 'ReadKey', sensorChannelReadKey);

% average_humeratures = zeros(4, NUM_OF_HOURS);
% std_hum = zeros(4, NUM_OF_HOURS);

times = internet_times;
start = datetime('yesterday');
start = start + hours(last_hour);

pos_err = zeros(NUM_OF_HOURS, NUM_OF_SENSORS);
median_hum = zeros(NUM_OF_HOURS, NUM_OF_SENSORS);
neg_err = zeros(NUM_OF_HOURS, NUM_OF_SENSORS);

plot_internet_hum = zeros(NUM_OF_HOURS, 1); 

for i = 0:(NUM_OF_HOURS-1)
    
    % get data from selected hour
    hourly_hum = hum(time >= start+hours(i) & time < start+hours(i + 1), :);
    times(i+1) = start+hours(i) + minutes(30);
    
    plot_internet_hum(i+1) = mean(internet_hum(internet_times >= start+hours(i) & internet_times < start+hours(i + 1)));
    
    % find Q1, Q2 Q3
    for j = 1:NUM_OF_SENSORS
        
       sensor = hourly_hum(~isnan(hourly_hum(:, j)), j);
       
       % get Q1, Q2, Q3
       q1 = prctile(sensor, 25);
       median_hum(i+1, j) = median(sensor);
       q3 = prctile(sensor, 75);
 
       if ~isempty(sensor)
           
           % get IRQ
           IRQ = abs(q3-q1);

           pos_err(i+1, j) = abs(median_hum(i+1, j) - max(sensor(sensor <= q3+3/2*IRQ)));
           neg_err(i+1, j) = abs(median_hum(i+1, j) - min(sensor(sensor >= q1-3/2*IRQ)));
       end
       
    end
    
end

% plot data
b = bar(times, plot_internet_hum, 1, "FaceAlpha",0.5, 'linestyle', '--');
% b.BaseValue = 50;
% a = area(times, internet_hum,"FaceAlpha",0.5, 'linestyle', '--');
% a.BaseValue = 50;
% plot(times, plot_internet_hum, "color", "#4DBEEE", "linewidth", 20);  
% bar(times, internet_hum, 'linestyle', '--', "linewidth", 1.5); 
hold on
% errorbar([times,times,times,times], median_hum,lower_outlier, upper_outlier, '-o', "linewidth", 1.5, "MarkerSize",8, "capsize", 10);
errorbar(repmat(times, [1, NUM_OF_SENSORS]), median_hum,neg_err, pos_err, '-o', "linewidth", 1.5, "MarkerSize",8, "capsize", 10);
hold off
grid minor
xlabel("date");
xticks(times(1:3:NUM_OF_HOURS));
ylabel("Humidity [%]");
legend(["Internet", "SHT31", "DHT11", "DHT22"], "Location", "eastoutside")
title("Last 24 hour humidity");
ylim([min(min(median_hum - neg_err))-5, (max(max(median_hum+ pos_err))+5)]);