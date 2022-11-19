% channel IDs and keys
sensorChannelID = 1883175;
sensorChannelReadKey = '77REZTLTX4JJ12XN'; 
temperatureFieldID = [1 3 4 6 8]; 

internetChannel = 1890915;
internetChannelReadKey = 'CT8EQRAQBZGWLM2L';

NUM_OF_HOURS = 25;
NUM_OF_SENSORS = size(temperatureFieldID, 2);

% get last 24 values from internet data
[internet_temp, internet_times] = thingSpeakRead(internetChannel, 'Fields', 1, 'NumPoints', NUM_OF_HOURS, 'ReadKey', internetChannelReadKey);
last_hour = hour(internet_times(end));

% current time
current_time = datetime('now');
additional_minutes = round(minutes(current_time-internet_times(end)));

% get last whole 24 hours
[temp, time] = thingSpeakRead(sensorChannelID, 'Fields', temperatureFieldID, 'NumMinutes', NUM_OF_HOURS*60+additional_minutes, 'ReadKey', sensorChannelReadKey);

% average_temperatures = zeros(4, NUM_OF_HOURS);
% std_temp = zeros(4, NUM_OF_HOURS);

times = internet_times;
start = datetime('yesterday');
start = start + hours(last_hour);

pos_err = zeros(NUM_OF_HOURS, NUM_OF_SENSORS);
median_temp = zeros(NUM_OF_HOURS, NUM_OF_SENSORS);
neg_err = zeros(NUM_OF_HOURS, NUM_OF_SENSORS);

for i = 0:(NUM_OF_HOURS-1)
    
    % get data from selected hour
    hourly_temp = temp(time >= start+hours(i) & time < start+hours(i + 1), :);
    times(i+1) = start+hours(i) + minutes(30);
    
    % find Q1, Q2 Q3
    for j = 1:NUM_OF_SENSORS
        
       sensor = hourly_temp(~isnan(hourly_temp(:, j)), j);
       
       % get Q1, Q2, Q3
       q1 = prctile(sensor, 25);
       median_temp(i+1, j) = median(sensor);
       q3 = prctile(sensor, 75);
 
       if ~isempty(sensor)
           
           % get IRQ
           IRQ = abs(q3-q1);

           pos_err(i+1, j) = max(sensor(sensor <= q3+3/2*IRQ));
           neg_err(i+1, j) = min(sensor(sensor >= q1-3/2*IRQ));
       end
       
    end
    
end

% plot data
bar(times, internet_temp, "FaceAlpha",0.5);
hold on
% errorbar([times,times,times,times], median_temp,lower_outlier, upper_outlier, '-o', "linewidth", 1.5, "MarkerSize",8, "capsize", 10);
errorbar(repmat(times, [1, NUM_OF_SENSORS]), median_temp,neg_err, pos_err, '-o', "linewidth", 1.5, "MarkerSize",8, "capsize", 10);
hold off
grid minor
xlabel("date");
xticks(times(1:3:NUM_OF_HOURS));
ylabel("temperature [\circC]");
legend(["Internet", "SHT31", "BMP280", "DS18B20", "DHT11", "DHT22"], "Location", "eastoutside")
title("Last 24 hour temperature");