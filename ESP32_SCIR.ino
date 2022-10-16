#include <Arduino.h>
#include <Wire.h>

// SHT31
#include "Adafruit_SHT31.h"

// BMP280
#include <Adafruit_BMP280.h>

// DHT11 & DHT22
#include "DHT.h"

// DS18B20
#include <OneWire.h>
#include <DallasTemperature.h>

// ThingSpeak / Wifi
#include <WiFi.h>
#include "secrets.h"
#include "ThingSpeak.h"

Adafruit_SHT31 sht31 = Adafruit_SHT31();

Adafruit_BMP280 bmp;

DHT dht11(5, DHT11);
DHT dht22(4, DHT22);

#define ONE_WIRE_BUS 18
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature dsTemp(&oneWire);

String ThingSpeakStatus = "";

unsigned int delayTime = 20000;

#define LED_PIN 2

// ------------------------------------------- THING SPEAK / WIFI -------------------------------------------/
char ssid[] = SECRET_SSID;
char pass[] = SECRET_PASS;
WiFiClient  client;

unsigned long myChannelNumber = SECRET_CH_ID;
const char * myWriteAPIKey = SECRET_WRITE_APIKEY;

void setup() {
  WiFi.mode(WIFI_STA);   
  ThingSpeak.begin(client);

  if(WiFi.status() != WL_CONNECTED){
    while(WiFi.status() != WL_CONNECTED){
      WiFi.begin(ssid, pass); 
      delay(5000);     
    } 
  }

  if (!bmp.begin()) {
    ThingSpeakStatus = "Error with BMP280";
    ThingSpeak.setStatus(myStatus);
    ThingSpeak.writeFields(myChannelNumber, myWriteAPIKey);
    delay(60000);
    ESP.restart();
  }

  if (!sht31.begin(0x44)) {
    ThingSpeakStatus = "Error with SHT31";
    ThingSpeak.setStatus(myStatus);
    ThingSpeak.writeFields(myChannelNumber, myWriteAPIKey);
    delay(60000);
    ESP.restart();
  }

  dht11.begin();
  dht22.begin();

  dsTemp.begin();

  pinMode(LED_PIN,OUTPUT);

}

void loop() {
  
  if(WiFi.status() != WL_CONNECTED){
    while(WiFi.status() != WL_CONNECTED){
      WiFi.begin(ssid, pass);
      delay(500);     
    } 
  }

  float t = sht31.readTemperature();
  float h = sht31.readHumidity();

  float t2 = bmp.readTemperature();

  float h11 = dht11.readHumidity();
  float t11 = dht11.readTemperature();

  float h22 = dht22.readHumidity();
  float t22 = dht22.readTemperature();

  // temperatura 85*C to "temperatura" resetu. Aby odczytać zmierzona temperature trzeba wywolac
  // polecenie requestTemperatures...
  dsTemp.requestTemperatures();
  float tDS = dsTemp.getTempCByIndex(0);

  // SHT31
  ThingSpeak.setField(1, t);
  ThingSpeak.setField(2, h);

  // MBP280
  ThingSpeak.setField(3, t2);

  // DHT11
  ThingSpeak.setField(4, t11);
  ThingSpeak.setField(5, h11);

  // DHT22
  ThingSpeak.setField(6, t22);
  ThingSpeak.setField(7, h22);

  // DS18B20
  ThingSpeak.setField(8, tDS);

  int x = ThingSpeak.writeFields(myChannelNumber, myWriteAPIKey);
  if(x == 200) {
    digitalWrite(LED_PIN, HIGH);
    delay(100);
    digitalWrite(LED_PIN, LOW);
  } else {
    digitalWrite(LED_PIN, HIGH);
  }

  delay(delayTime);

}
