clear global
close all
%% 
filename = "feeds_2023_01_05.csv";
feeds = readtable(filename);
dates = datetime(table2array(feeds(:, 1)),'InputFormat', 'yyyy-MM-dd''T''HH:mm:ssXXX','TimeZone','Europe/Zurich');
temp = table2array([feeds(:, 3), feeds(:, 5), feeds(:, 6), feeds(:, 8), feeds(:, 10)]);
hum = table2array([feeds(:, 4), feeds(:, 7), feeds(:, 9)]);

filename_internet = "feeds_internet_2023_01_05.csv";
feeds_internet = readtable(filename_internet);
dates_int = datetime(table2array(feeds_internet(:, 1)),'InputFormat', 'yyyy-MM-dd''T''HH:mm:ssXXX','TimeZone','UTC');
dates_int = dates_int(65:end);
temp_int = table2array(feeds_internet(:, 3));
temp_int = temp_int(65:end);
hum_int = table2array(feeds_internet(:, 4));
hum_int = hum_int(65:end);

temp2 = temp;
for col=1:size(temp2, 1)
   for row=1:size(temp2, 2)
       if (temp(col, row) < -40 || temp(col, row) > 40)
            temp2(col, row) = NaN;
       end
   end
end

figure()
sgtitle("Pomiar temperatury i wilgotności")
subplot(2,1,1)
plot(dates, temp2)
hold on
stairs(dates_int, temp_int, "--k")
hold off
grid on
title("Temperatura")
ylabel("Temperatura [\circC]")
xlabel("Data")
legend(["SHT31", "BMP280", "DHT11", "DHT22", "DS18B20", "internet"], "Location", "southoutside", "Orientation", "horizontal")
% ylim([-40, 40]);
xlim([dates(1), dates(end)])
subplot(2,1,2)
plot(dates, hum)
hold on
stairs(dates_int, hum_int, "--k")
hold off
grid on
% ylim([50, 105]);
title("Wilgotność")
ylabel("Wilgotność [%]")
xlabel("Data")
legend(["SHT31", "DHT11", "DHT22", "internet"], "Location", "southoutside", "Orientation", "horizontal")
xlim([dates(1), dates(end)])

%% dateshift - hourly
dates_int_shifted = dateshift(dates_int, 'start', 'hour');
dates_shifted = dateshift(dates, 'start', 'hour');
dates_unique = unique(dates_shifted);

temp_hourly = zeros(size(dates_unique, 1), 5);
temp_int_hourly = NaN(size(dates_unique, 1), 1);

hum_hourly = zeros(size(dates_unique, 1), 3);
hum_int_hourly = NaN(size(dates_unique, 1), 1);

for i = 1:size(dates_unique, 1)
    
    % temperature
    selected_temperatures = temp2(dates_shifted == dates_unique(i), :);
    avg_temp = mean(selected_temperatures,'omitnan');
    temp_hourly(i, :) = avg_temp;
    temp_int_hourly(i) = mean(temp_int(dates_int_shifted == dates_unique(i)));
    
    % humidity
    selected_hums = hum(dates_shifted == dates_unique(i), :);
    avg_hum = mean(selected_hums,'omitnan');
    hum_hourly(i, :) = avg_hum;
    hum_int_hourly(i) = mean(hum_int(dates_int_shifted == dates_unique(i)));
    
end

temp_rms = rmse(temp_int_hourly, temp_hourly,"omitnan");
hum_rms = rmse(hum_int_hourly, hum_hourly,"omitnan");

figure()
sgtitle("Cogodzinne uśrednienie pomiaru temperatury i wilgotności")

% plot temperature
subplot(2,1,1)
plot(dates_unique, temp_hourly, "Linewidth", 1)
hold on
plot(dates_unique, temp_int_hourly, "--k", "Linewidth", 1)
hold off
grid on
title("Temperatura")
ylabel("Temperatura [\circC]")
xlabel("Data")
legend(["SHT31", "BMP280", "DHT11", "DHT22", "DS18B20", "internet"], "Location", "southoutside", "Orientation", "horizontal")
xlim([dates_unique(1), dates_unique(end)])

% plot humidity
subplot(2,1,2)
plot(dates_unique, hum_hourly, "Linewidth", 1)
hold on
plot(dates_unique, hum_int_hourly, "--k", "Linewidth", 1)
hold off
grid on
title("Wilgotność")
ylabel("Wilgotność [%]")
xlabel("Data")
legend(["SHT31", "DHT11", "DHT22", "internet"], "Location", "southoutside", "Orientation", "horizontal")
xlim([dates_unique(1), dates_unique(end)])

%% korelacja czujnik - internet
correlation_int_temp = corr(temp_hourly, temp_int_hourly, "rows", "complete");
fprintf("Korelacja danych z czujników temperatury z danymi z internetu\n")
disp(correlation_int_temp)

correlation_int_temp = corr(hum_hourly, hum_int_hourly, "rows", "complete");
fprintf("Korelacja danych z czujników wilgotności z danymi z internetu\n")
disp(correlation_int_temp)

%% korelacja między czujnikami
correlation_sensors_temp = corr(temp2, "rows", "complete");
fprintf("Korelacja danych z czujników temperatury\n")
disp(correlation_sensors_temp)

correlation_sensors_hum = corr(hum, "rows", "complete");
fprintf("Korelacja danych z czujników wilgotności\n")
disp(correlation_sensors_hum)

%% odchylenie standardowe
dates_int_shifted = dateshift(dates_int, 'start', 'hour');
dates_shifted = dateshift(dates, 'start', 'hour');
dates_int_unique = unique(dates_int_shifted);

temp_hourly_sd = zeros(size(dates_int_unique, 1), 5);
% temp_int_avg = NaN(size(dates_int_unique, 1), 1);

hum_hourly_sd = zeros(size(dates_int_unique, 1), 3);
% hum_int_avg = NaN(size(dates_int_unique, 1), 1);

for i = 1:size(dates_int_unique, 1)
    
    % temperature
    selected_temperatures = temp2(dates_shifted == dates_int_unique(i), :);
    temp_hourly_sd(i) = mean(selected_temperatures,'omitnan');
    temp_int_avg = mean(temp_int(datenum(dates_int_shifted) == datenum(dates_int_unique(i))),'omitnan');
    
    % humidity
    selected_hums = hum(dates_shifted == dates_int_unique(i), :);
    hum_hourly_sd(i) = mean(selected_temperatures,'omitnan');
    hum_int_avg = mean(hum_int(datenum(dates_int_shifted) == datenum(dates_int_unique(i))),'omitnan');
    
end

plot(dates_int_unique, temp_hourly_sd)

%% dateshift - daily
dates_int_shifted = dateshift(dates_int, 'start', 'day');
dates_shifted = dateshift(dates, 'start', 'day');
dates_unique = unique(dates_shifted);

temp_daily = NaN(size(dates_unique, 1), 5);
temp_daily_min = NaN(size(dates_unique, 1), 5);
temp_daily_max = NaN(size(dates_unique, 1), 5);

temp_int_daily = NaN(size(dates_unique, 1), 1);
temp_int_daily_min = NaN(size(dates_unique, 1), 1);
temp_int_daily_max = NaN(size(dates_unique, 1), 1);

hum_daily = NaN(size(dates_unique, 1), 3);
hum_int_daily = NaN(size(dates_unique, 1), 1);

for i = 1:size(dates_unique, 1)
    
    % temperature
    selected_temperatures = temp2(dates_shifted == dates_unique(i), :);
    temp_daily(i, :) = mean(selected_temperatures,'omitnan');
    temp_daily_min(i, :) = min(selected_temperatures);
    temp_daily_max(i, :) = max(selected_temperatures);

    temp_int_daily(i) = mean(temp_int(datenum(dates_int_shifted) == datenum(dates_unique(i))),'omitnan');
    if ~isnan(temp_int_daily(i))
        temp_int_daily_min(i) = min(temp_int(datenum(dates_int_shifted) == datenum(dates_unique(i))));
        temp_int_daily_max(i) = max(temp_int(datenum(dates_int_shifted) == datenum(dates_unique(i))));
    end
    
    % humidity
    selected_hums = hum(dates_shifted == dates_unique(i), :);
    avg_hum = mean(selected_hums,'omitnan');
    hum_daily(i, :) = avg_hum;
    hum_int_daily(i) = mean(hum_int(datenum(dates_int_shifted) == datenum(dates_unique(i))),'omitnan');
    
end

figure()
sgtitle("Dzienne uśrednienie pomiaru temperatury i wilgotności")

% plot temperature
subplot(2,1,1)
scatter(dates_unique, temp_int_daily, "MarkerEdgeColor", "black" , "MarkerFaceColor", "green", "Linewidth", 1)
hold on
scatter(dates_unique, temp_daily, "MarkerFaceColor", "flat", "MarkerFaceAlpha", 0.5, "Linewidth", 1)
hold off
grid on
title("Temperatura")
ylabel("Temperatura [\circC]")
xlabel("Data")
legend(["internet", "SHT31", "BMP280", "DHT11", "DHT22", "DS18B20"], "Location", "southoutside", "Orientation", "horizontal")
xlim([dates_unique(1), dates_unique(end)])

% plot humidity
subplot(2,1,2)
scatter(dates_unique, hum_int_daily, "MarkerEdgeColor", "black" , "MarkerFaceColor", "black", "Linewidth", 1)
hold on
scatter(dates_unique, hum_daily, "MarkerFaceColor", "flat", "MarkerFaceAlpha", 0.5, "Linewidth", 1)
hold off
grid on
title("Wilgotność")
ylabel("Wilgotność [%]")
xlabel("Data")
legend(["internet", "SHT31", "DHT11", "DHT22"], "Location", "southoutside", "Orientation", "horizontal")
xlim([dates_unique(1), dates_unique(end)])

figure()
scatter(dates_unique, temp_daily(:, 5), "MarkerFaceColor", "flat", "MarkerFaceAlpha", 0.5, "Linewidth", 1)
hold on
scatter(dates_unique, temp_daily_max(:, 5), "MarkerFaceColor", "flat", "MarkerFaceAlpha", 0.5, "Linewidth", 1)
scatter(dates_unique, temp_daily_min(:, 5), "MarkerFaceColor", "flat", "MarkerFaceAlpha", 0.5, "Linewidth", 1)
hold off
grid on
title("Dzienna wartość temperatury dla czujnika DS18B20")
ylabel("Temperatura [\circC]")
xlabel("Data")
legend(["średnia", "maximum", "minimum"], "Location", "southoutside", "Orientation", "horizontal")
xlim([dates_unique(1), dates_unique(end)])
