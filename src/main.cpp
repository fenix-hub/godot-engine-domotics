#include <Arduino.h>
#include <ArduinoJson.h>
#include <ESP8266WiFi.h>
#include <ESPAsyncWebServer.h>
#include "AsyncJson.h"
#include "ArduinoJson.h"

AsyncWebServer server(80);

const String name = "TP-LINK_4C02FE";
const String password = "08738820";

String header = "";

String output1state = "off";
String output2state = "off";

const int output1 = 15; // D8
const int input1 = A0;

const int pinRosso = 14; //D5
const int pinVerde = 12; //D6
const int pinBlu = 13; //D7

int moisturevalue = 0;

void homePage(AsyncWebServerRequest *request) {
  request->send(200,"text/html","connected");
  String message = "home requested";
  Serial.println(message);
}

void output1control(AsyncWebServerRequest *request) { 
  output1state = (output1state == "off") ? "on" : "off";
  digitalWrite(output1, (output1state == "on") ? HIGH : LOW);
  request->send(200, "text/html", "control output 1");
  Serial.println("output 1 control requested ");
}

void moisture(AsyncWebServerRequest *request) {
  request->send(200, "text/html", String(analogRead(input1)));
  Serial.println("requested moisture");
}

void colore (int rosso, int verde, int blu)
{
 analogWrite(pinRosso, rosso); //attiva il led rosso con l’intensita’ definita nella variabile rosso
 analogWrite(pinVerde, verde); //attiva il led verde con l’intensita’ definita nella variabile verde
 analogWrite(pinBlu, blu); //attiva il led blu con l’intensita’ definita nella variabile blu
}

void setup() {
  Serial.begin(115200);

  pinMode(output1, OUTPUT);
  pinMode(pinRosso, OUTPUT);
  pinMode(pinVerde, OUTPUT);
  pinMode(pinBlu, OUTPUT);
  pinMode(input1, INPUT);

  digitalWrite(output1, LOW);

  WiFi.begin(name, password);

  Serial.println("Connecting...");
  while(WiFi.status() != WL_CONNECTED ) 
  {
    Serial.println("connecting in 500ms, please wait...");
    delay(500);
  }
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());

  // ---
  server.on("/", HTTP_GET, homePage);
  server.on("/output1", HTTP_GET, output1control);
  server.on("/moisture", HTTP_GET, moisture);
  server.on("/color", HTTP_GET, [](AsyncWebServerRequest *request){
      //nothing and dont remove it
    }, NULL, [](AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total){
      Serial.println("requested new color");
      DynamicJsonDocument JsonDocument(2048);
      DeserializationError json = deserializeJson(JsonDocument,data);
      if (json) {
        Serial.println("error");
        request->send(404, "text/plain", "can't serialize color");
      }
      else {
        int rosso = JsonDocument["r"];
        int verde = JsonDocument["g"];
        int blu = JsonDocument["b"];
        Serial.print(rosso); Serial.print(","); Serial.print(verde); Serial.print(","); Serial.println(blu);
        colore(rosso,verde,blu);
        request->send(200, "text/html", "color changed");
      }
    });
  
  server.begin();
}


void loop() {}
