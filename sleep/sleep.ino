#define NOTE_B0  31
#define NOTE_C1  33
#define NOTE_CS1 35
#define NOTE_D1  37
#define NOTE_DS1 39
#define NOTE_E1  41
#define NOTE_F1  44
#define NOTE_FS1 46
#define NOTE_G1  49
#define NOTE_GS1 52
#define NOTE_A1  55
#define NOTE_AS1 58
#define NOTE_B1  62
#define NOTE_C2  65
#define NOTE_CS2 69
#define NOTE_D2  73
#define NOTE_DS2 78
#define NOTE_E2  82
#define NOTE_F2  87
#define NOTE_FS2 93
#define NOTE_G2  98
#define NOTE_GS2 104
#define NOTE_A2  110
#define NOTE_AS2 117
#define NOTE_B2  123
#define NOTE_C3  131
#define NOTE_CS3 139
#define NOTE_D3  147
#define NOTE_DS3 156
#define NOTE_E3  165
#define NOTE_F3  175
#define NOTE_FS3 185
#define NOTE_G3  196
#define NOTE_GS3 208
#define NOTE_A3  220
#define NOTE_AS3 233
#define NOTE_B3  247
#define NOTE_C4  262
#define NOTE_CS4 277
#define NOTE_D4  294
#define NOTE_DS4 311
#define NOTE_E4  330
#define NOTE_F4  349
#define NOTE_FS4 370
#define NOTE_G4  392
#define NOTE_GS4 415
#define NOTE_A4  440
#define NOTE_AS4 466
#define NOTE_B4  494
#define NOTE_C5  523
#define NOTE_CS5 554
#define NOTE_D5  587
#define NOTE_DS5 622
#define NOTE_E5  659
#define NOTE_F5  698
#define NOTE_FS5 740
#define NOTE_G5  784
#define NOTE_GS5 831
#define NOTE_A5  880
#define NOTE_AS5 932
#define NOTE_B5  988
#define NOTE_C6  1047
#define NOTE_CS6 1109
#define NOTE_D6  1175
#define NOTE_DS6 1245
#define NOTE_E6  1319
#define NOTE_F6  1397
#define NOTE_FS6 1480
#define NOTE_G6  1568
#define NOTE_GS6 1661
#define NOTE_A6  1760
#define NOTE_AS6 1865
#define NOTE_B6  1976
#define NOTE_C7  2093
#define NOTE_CS7 2217
#define NOTE_D7  2349
#define NOTE_DS7 2489
#define NOTE_E7  2637
#define NOTE_F7  2794
#define NOTE_FS7 2960
#define NOTE_G7  3136
#define NOTE_GS7 3322
#define NOTE_A7  3520
#define NOTE_AS7 3729
#define NOTE_B7  3951
#define NOTE_C8  4186
#define NOTE_CS8 4435
#define NOTE_D8  4699
#define NOTE_DS8 4978

// notes in the melody:
int melody[] = {
  NOTE_C4, NOTE_G3, NOTE_G3, NOTE_A3, NOTE_G3, 0, NOTE_B3, NOTE_C4
};

// note durations: 4 = quarter note, 8 = eighth note, etc.:
int noteDurations[] = {
  4, 8, 8, 4, 4, 4, 4, 4
};



#include <Adafruit_Sensor.h>
#include <Adafruit_ADXL345_U.h>
#include <WiFi101.h>
#include <RTCZero.h>

#define infraPIN 6
#define speakerPIN 10
#define flushPIN 11

volatile byte infra_state = LOW;

char ssid[] = "TECATE4"; //  your network SSID (name)
char pass[] = "bobsburgers";    // your network password (use for WPA, or use as key for WEP)
int keyIndex = 0;            // your network key Index number (needed only for WEP)

unsigned long last_flush = 0;
unsigned long flush_timeout = 1000*120; //2 minute time out on flush // somethiung wrong with timer?

RTCZero rtc;

int status = WL_IDLE_STATUS;
// if you don't want to use DNS (and reduce your sketch size)
// use the numeric IP instead of the name for the server:
//IPAddress server(74,125,232,128);  // numeric IP for Google (no DNS)
char server[] = "www.shittykitty.online";    // name address for Google (using DNS)

// Initialize the Ethernet client library
// with the IP address and port of the server
// that you want to connect to (port 80 is default for HTTP):
WiFiClient client;

/* Assign a unique ID to this sensor at the same time */
Adafruit_ADXL345_Unified accel = Adafruit_ADXL345_Unified(12345);

void blink(int j) {
  for (int i=0; i<10; i++) {
    delayMicroseconds(j*50000);
    digitalWrite(13, HIGH);
    delayMicroseconds(j*50000);
    digitalWrite(13, LOW);
  }
}

void setup() {
  blink(2);
  rtc.begin();
  pinMode(infraPIN, INPUT);
  if(!accel.begin()) {
    /* There was a problem detecting the ADXL345 ... check your connections */
    Serial.println("Ooops, no ADXL345 detected ... Check your wiring!");
    while(1);
  }
  
  delay(10000);
  //Wait until the serial monitor is ready/open
  Serial.begin(9600);
  //while (!Serial) {
  //  ; // wait for serial port to connect. Needed for native USB port only
  //}
  Serial.println("Starting");

  //Configure pins for Adafruit ATWINC1500 Feather
  WiFi.setPins(8,7,4,2);
  WiFi.maxLowPowerMode();
  // check for the presence of the shield:
  if (WiFi.status() == WL_NO_SHIELD) {
    Serial.println("WiFi shield not present");
    // don't continue:
    while (true);
  }

  // attempt to connect to Wifi network:
  while (status != WL_CONNECTED) {
    Serial.print("Attempting to connect to SSID: ");
    Serial.println(ssid);
    // Connect to WPA/WPA2 network. Change this line if using open or WEP network:
    status = WiFi.begin(ssid, pass);

    // wait 10 seconds for connection:
    delay(10000);
  }
  
  blink(3);
  Serial.println("Connected to wifi");
  printWifiStatus();




  pinMode(13, OUTPUT);
  digitalWrite(13, LOW);

  //pinMode(infraPIN, INPUT_PULLUP);
  pinMode(infraPIN, INPUT);
  //Attach the interrupt to RISING event
  //attachInterrupt(infraPIN, ISR, LOW);
  //attachInterrupt(infraPIN, ISR, CHANGE);
  attachInterrupt(infraPIN, ISR, CHANGE);

  // Set the XOSC32K to run in standby
SYSCTRL->XOSC32K.bit.RUNSTDBY = 1;

// Configure EIC to use GCLK1 which uses XOSC32K 
// This has to be done after the first call to attachInterrupt()
GCLK->CLKCTRL.reg = GCLK_CLKCTRL_ID(GCM_EIC) | 
                    GCLK_CLKCTRL_GEN_GCLK1 | 
                    GCLK_CLKCTRL_CLKEN;

  //EIC->WAKEUP.reg |= (1 << digitalPinToInterrupt(infraPIN));

  //Set sleep mode
  //SCB->SCR |= SCB_SCR_SLEEPDEEP_Msk;
}

void ISR() {
  infra_state = HIGH;
  //serial.println("ISR");
}

void flush() {
        analogWrite(flushPIN,255);
        delay(20);
        analogWrite(flushPIN,0);
        delay(20);
        analogWrite(flushPIN,255);
        delay(20);
        analogWrite(flushPIN,0);
        delay(20);
}

void loop() {

  accel.writeRegister(ADXL345_REG_POWER_CTL,0x0);
  //Serial.println("Sleep");
  
  //delay(300);

  // SAMD sleep
  
  //attachInterrupt(infraPIN, ISR, LOW);
  //__WFI();
  delay(100);
  rtc.standbyMode();
  
  //delay(300);
  //detachInterrupt(infraPIN);
  

  //Serial.println("Awake");


  tone(speakerPIN,500,100);
  delay(100);

  if (infra_state==HIGH) {
    //turn on the accelerometer
    accel.writeRegister(ADXL345_REG_POWER_CTL,0x08);
    delay(200);
    blink(1);
    //lets get the gravity?
    sensors_event_t event; 
    accel.getEvent(&event); 
  //Serial.println(event.acceleration.z);
  
    if (event.acceleration.z<=-9.5) {
      digitalWrite(13, HIGH);
      unsigned long current_time = millis();
      
      /*bool flush_now = false; 
      if (last_flush==0) {
        flush_now=true;
      } else if (current_time<last_flush) {
        flush_now=true;
      } else if (current_time-last_flush>flush_timeout) {
        flush_now=true;
      }*/
      bool flush_now=true;
      
      Serial.println(event.acceleration.z);
      Serial.println(current_time);
      Serial.println(last_flush);
      Serial.println(flush_timeout);
  
      if (flush_now) {
        //Serial.println("GOING TO FLUSH");
        delay(20*1000);
        play_melody();
  
        flush();
        last_flush=millis();
                
        //now lets do some work
        //delay(500);
      
        Serial.println("\nStarting connection to server...");
        // if you get a connection, report back via serial:
        if (client.connect(server, 80)) {
          Serial.println("connected to server");
          // Make a HTTP request:
          client.println("GET /api/pooped HTTP/1.1");
          client.print("Host: ");
          client.println(server);
          client.println("Connection: close");
          client.println();
          client.stop();
        }
      } else {
        //Serial.println("NOT GOING TO FLUSH");
      }
      accel.writeRegister(ADXL345_REG_POWER_CTL,0x0);
      for (int i=0; i<flush_timeout; i+=200) {
        digitalWrite(13, LOW);
        delay(100);
        digitalWrite(13, HIGH);
        delay(100);
      }
      //delay(flush_timeout);//otherwise clock sleeps! no time!
    }
    
    infra_state=LOW;
    
    digitalWrite(13, LOW);
    //attachInterrupt(infraPIN, ISR, HIGH);
  } else {
    //Serial.println("no intterupt found?");
  }

}

void printWifiStatus() {
  // print the SSID of the network you're attached to:
  Serial.print("SSID: ");
  Serial.println(WiFi.SSID());

  // print your WiFi shield's IP address:
  IPAddress ip = WiFi.localIP();
  Serial.print("IP Address: ");
  Serial.println(ip);

  // print the received signal strength:
  long rssi = WiFi.RSSI();
  Serial.print("signal strength (RSSI):");
  Serial.print(rssi);
  Serial.println(" dBm");
}

void play_melody() {
  // iterate over the notes of the melody:
  for (int thisNote = 0; thisNote < 8; thisNote++) {

    // to calculate the note duration, take one second
    // divided by the note type.
    //e.g. quarter note = 1000 / 4, eighth note = 1000/8, etc.
    int noteDuration = 1000 / noteDurations[thisNote];
    tone(speakerPIN, melody[thisNote], noteDuration);

    // to distinguish the notes, set a minimum time between them.
    // the note's duration + 30% seems to work well:
    int pauseBetweenNotes = noteDuration * 1.30;
    delay(pauseBetweenNotes);
    // stop the tone playing:
    noTone(speakerPIN);
  }
}
