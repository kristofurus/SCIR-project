% channel IDs and keys
sensorChannelID = 1883175;
sensorChannelReadKey = '77REZTLTX4JJ12XN'; 
humidityFieldID = [2 5 7]; 

internetChannel = 1890915;
internetChannelReadKey = 'CT8EQRAQBZGWLM2L';

NUM_OF_HOURS = 24;
NUM_OF_SENSORS = size(humidityFieldID, 2);

% get last 24 values from internet data
[internet_hum, internet_times] = thingSpeakRead(internetChannel, 'Fields', 2, 'NumMinutes', NUM_OF_HOURS*60, 'ReadKey', internetChannelReadKey);
last_hour = hour(internet_times(end));

% get last whole 24 hours
[hum, time] = thingSpeakRead(sensorChannelID, 'Fields', humidityFieldID, 'NumMinutes', NUM_OF_HOURS*60, 'ReadKey', sensorChannelReadKey);

dates_int = dateshift(internet_times, 'start', 'hour');
dates = dateshift(time, 'start', 'hour');
dates_unique = unique(dates);

pos_err = zeros(size(dates_unique, 1), NUM_OF_SENSORS);
median_hum = zeros(size(dates_unique, 1), NUM_OF_SENSORS);
neg_err = zeros(size(dates_unique, 1), NUM_OF_SENSORS);

for i = 1:size(dates_unique, 1)
    
    selected_hum = hum(dates == dates_unique(i), :);

    for j = 1:NUM_OF_SENSORS
        
        sensor = selected_hum(~isnan(selected_hum(:, j)), j);
       
        % get Q1, Q2, Q3
        q1 = prctile(sensor, 25);
        median_hum(i, j) = median(sensor);
        q3 = prctile(sensor, 75);
 
        if ~isempty(sensor)

            % get IRQ
            IRQ = abs(q3-q1);
            pos_err(i, j) = abs(median_hum(i, j) - max(sensor(sensor <= q3+3/2*IRQ)));
            neg_err(i, j) = abs(median_hum(i, j) - min(sensor(sensor >= q1-3/2*IRQ)));
        
        end
    end
end

% plot data
stairs(dates_int, internet_hum , "--", "color", "#000000", "linewidth", 2);  
hold on
errorbar(repmat(dates_unique, [1, NUM_OF_SENSORS]), median_hum, neg_err, pos_err, '-o', "linewidth", 1.5, "MarkerSize",8, "capsize", 10);
hold off
grid minor
xlabel("date");
xticks(dates_unique(1:3:NUM_OF_HOURS));
ylabel("Humidity [%]");
legend(["Internet", "SHT31", "DHT11", "DHT22"], "Location", "eastoutside")
title("Last 24 hour humidity");
ylim([min(min(median_hum - neg_err))-5, (max(max(median_hum+ pos_err))+5)]);