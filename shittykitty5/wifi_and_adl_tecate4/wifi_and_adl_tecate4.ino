

/**
 * BasicHTTPClient.ino
 *
 *  Created on: 24.05.2015
 *
 */

#include <Arduino.h>
#include <Servo.h> 

 static const uint8_t D0   = 16;
static const uint8_t D1   = 5;
static const uint8_t D2   = 4;
static const uint8_t D3   = 0;
static const uint8_t D4   = 2;
static const uint8_t D5   = 14;
static const uint8_t D6   = 12;
static const uint8_t D7   = 13;
static const uint8_t D8   = 15;
static const uint8_t D9   = 3;
static const uint8_t D10  = 1;
 
#include <ESP8266WiFi.h>
#include <ESP8266WiFiMulti.h>

#include <ESP8266HTTPClient.h>
//ADXL345
#define DEVICE (0x53) 
#include <Wire.h>

#define USE_SERIAL Serial
//int servoPin = 14; //D5 https://raw.githubusercontent.com/nodemcu/nodemcu-devkit-v1.0/master/Documents/NODEMCU_DEVKIT_V1.0_PINMAP.png
int servoPin = D6; //D6 https://raw.githubusercontent.com/nodemcu/nodemcu-devkit-v1.0/master/Documents/NODEMCU_DEVKIT_V1.0_PINMAP.png
int irAPin = D7;
int irBPin = D5;
int irLongPin = A0;
Servo servo;  
int angle = 0;   // servo position in degrees 

#define ADXL345_MG2G_MULTIPLIER (0.004)
#define SENSORS_GRAVITY_STANDARD          (SENSORS_GRAVITY_EARTH)
#define SENSORS_GRAVITY_EARTH             (9.80665F)              /**< Earth's gravity in m/s^2 */

byte _buff[6];
char POWER_CTL = 0x2D;    //Power Control Register
char DATA_FORMAT = 0x31;
char DATAX0 = 0x32;    //X-Axis Data 0
char DATAX1 = 0x33;    //X-Axis Data 1
//char DATAY0 = 0x34;    //Y-Axis Data 0
//char DATAY1 = 0x35;    //Y-Axis Data 1
//char DATAZ0 = 0x36;    //Z-Axis Data 0
//char DATAZ1 = 0x37;    //Z-Axis Data 1

float max_x=0;
float min_x=0;
float cal_x=0;
float x = 0;
ESP8266WiFiMulti WiFiMulti;


float readAccel() 
{
  //Serial.print("readAccel");
  uint8_t howManyBytesToRead = 6; //6 for all axes
  readFrom( DATAX0, howManyBytesToRead, _buff); //read the acceleration data from the ADXL345
  short x =0;
  short y =0;
  short z =0;
   x = (((short)_buff[1]) << 8) | _buff[0];
   y = (((short)_buff[3]) << 8) | _buff[2];
   z = (((short)_buff[5]) << 8) | _buff[4];
  //short y = (((short)_buff[3]) << 8) | _buff[2];
  //short z = (((short)_buff[5]) << 8) | _buff[4];
  //Serial.println("X " );
  //Serial.println(x * ADXL345_MG2G_MULTIPLIER * SENSORS_GRAVITY_STANDARD);
  //Serial.println("Y " );
  //Serial.println(y * ADXL345_MG2G_MULTIPLIER * SENSORS_GRAVITY_STANDARD);
  //Serial.println("Z " );
  Serial.println(z * ADXL345_MG2G_MULTIPLIER * SENSORS_GRAVITY_STANDARD);
  return z * ADXL345_MG2G_MULTIPLIER * SENSORS_GRAVITY_STANDARD;
  //x = x + cal_x;

  
  //Serial.print("x: "); 
  //Serial.print( x*2./512 );
  //Serial.print(" y: ");
  //Serial.print( y*2./512 );
  //Serial.print(" z: ");
  //Serial.print( z*2./512 );
  //Serial.print("X: "); Serial.print( x);

  //Serial.println( sqrtf(x*x+y*y+z*z)*2./512 );

//getX() = read16(ADXL345_REG_DATAX0);
//x = getX() * ADXL345_MG2G_MULTIPLIER * SENSORS_GRAVITY_STANDARD;
  
}

void writeTo(byte address, byte val) 
{
  Wire.beginTransmission(DEVICE); // start transmission to device
  Wire.write(address); // send register address
  Wire.write(val); // send value to write
  Wire.endTransmission(); // end transmission
}

// Reads num bytes starting from address register on device in to _buff array
void readFrom(byte address, int num, byte _buff[]) 
{
  Wire.beginTransmission(DEVICE); // start transmission to device
  Wire.write(address); // sends address to read from
  Wire.endTransmission(); // end transmission
  Wire.beginTransmission(DEVICE); // start transmission to device
  Wire.requestFrom(DEVICE, num); // request 6 bytes from device

  int i = 0;
  while(Wire.available()) // device may send less than requested (abnormal)
  {
    _buff[i] = Wire.read(); // receive a byte
    i++;
  }
  Wire.endTransmission(); // end transmission
}

int toilet_state=-1;
int toilet_open=40;
int toilet_closed=165;

void wiggle() {
  servo.attach(servoPin);
  int x = random(10);
  int inc = 1;
  if (x>5) {
     inc = 1;
  } else {
     inc = -1; 
  }
  inc=0;

  int start_angle = 0;
  if (toilet_state==1) {
    start_angle=toilet_closed;
  } else {
    start_angle=toilet_open;
  }
  servo.write(start_angle+inc);
  delay(75);
  servo.detach();
}

void move_toilet(int from, int to) {
  servo.attach(servoPin);
  if (to<from) {
    //opening
    for (int i=from; i>to; i-=1) {
      //move it
      servo.write(i); 
      delay(25);
    } 
  } else {
    //clsoing
    for (int i=from; i<to; i+=1) {
      //move it
      servo.write(i); 
      delay(15);
    } 
  }
  servo.detach();
}
void toilet(int x) {
  if (x==2) {
    if (toilet_state==0) {
      return;
    }
    servo.attach(servoPin);
    servo.write(toilet_open);  
    delay(500);
    servo.detach();
    toilet_state=0;
    return;
  }
  if (x==toilet_state) {
    return;
  }
  if (x==1) {
    //servo.write(120);
    move_toilet(toilet_open,toilet_closed); 
  } else {
    //servo.write(40);
    move_toilet(toilet_closed,toilet_open);  
  }
  toilet_state=x;
}

void setup() {

    USE_SERIAL.begin(115200);
   // USE_SERIAL.setDebugOutput(true);

    USE_SERIAL.println();
    USE_SERIAL.println();
    USE_SERIAL.println();

    pinMode(irAPin, INPUT);
    pinMode(irBPin, INPUT);
    pinMode(irLongPin, INPUT);

    for(uint8_t t = 4; t > 0; t--) {
        USE_SERIAL.printf("[SETUP] WAIT %d...\n", t);
        USE_SERIAL.flush();
        delay(1000);
    }

    WiFiMulti.addAP("TECATE4", "bobsburgers");

    //ADXL345
  // i2c bus SDA = GPIO0; SCL = GPIO2
  //Wire.begin(0,2); 
  Wire.begin(4,5); 

  
  // Put the ADXL345 into +/- 2G range by writing the value 0x01 to the DATA_FORMAT register.
  // FYI: 0x00 = 2G, 0x01 = 4G, 0x02 = 8G, 0x03 = 16G
  writeTo(DATA_FORMAT, 0x00);
  
  // Put the ADXL345 into Measurement Mode by writing 0x08 to the POWER_CTL register.
  writeTo(POWER_CTL, 0x08);

  int i =0;
  for(i=0; i<11; i++)
  {
    //uint8_t howManyBytesToRead = 6;
    //readFrom( DATAX0, howManyBytesToRead, _buff);
    float calib_x ;//= (((short)_buff[1]) << 8) | _buff[0];
    calib_x = readAccel();
    //if(i==0)
    // cal_x = x;
    if(i>0)
     cal_x = cal_x + calib_x;
    //Serial.println(calib_x);
    delay(100);
  }

  cal_x = cal_x/10;
  //Serial.print("cal_x: ");Serial.println(cal_x); 


  toilet(1); //open for business
}

int seat_up=0;
void loop() {
    // wait for WiFi connection
    if(1==0 && (WiFiMulti.run() == WL_CONNECTED)) {

        HTTPClient http;

        USE_SERIAL.print("[HTTP] begin...\n");
        // configure traged server and url
        //http.begin("https://192.168.1.12/test.html", "7a 9c f4 db 40 d3 62 5a 6e 21 bc 5c cc 66 c8 3e a1 45 59 38"); //HTTPS
        http.begin("http://192.168.1.12/test.html"); //HTTP

        USE_SERIAL.print("[HTTP] GET...\n");
        // start connection and send HTTP header
        int httpCode = http.GET();

        // httpCode will be negative on error
        if(httpCode > 0) {
            // HTTP header has been send and Server response header has been handled
            USE_SERIAL.printf("[HTTP] GET... code: %d\n", httpCode);

            // file found at server
            if(httpCode == HTTP_CODE_OK) {
                String payload = http.getString();
                USE_SERIAL.println(payload);
            }
        } else {
            USE_SERIAL.printf("[HTTP] GET... failed, error: %s\n", http.errorToString(httpCode).c_str());
        }

        http.end();
    }

    

    
  /*//setup servo
  servo.attach(servoPin);
  servo.write(110); 
// scan from 0 to 180 degrees
   int start_angle=0;
   int end_angle=210;
   //servo.write(90);      
  for(angle = start_angle; angle < end_angle; angle++)  
  {                                  
    servo.write(angle);               
    delay(15);                   
  } 
  // now scan back from 180 to 0 degrees
  for(angle = end_angle; angle > start_angle; angle--)    
  {                                
    servo.write(angle);           
    delay(15);       
  } 
  servo.detach();*/
  int delay_before_next=100;
  readAccel();
  unsigned int long_ir = analogRead(A0);
  unsigned int irA = digitalRead(irAPin);
  unsigned int irB = digitalRead(irBPin);

    //figure out if the seat is up
  if (readAccel()>-8.8) {
      seat_up++;
      delay_before_next=10;
    } else {
      seat_up--;
    } 
    if (seat_up>20) {
      seat_up=20;
    }
    if (seat_up<-5) {
      seat_up=-5;
    }
  


  if (seat_up>7) {
    toilet(2);
  } else if (long_ir<400 && (irA==1 || irB==1)) {
     toilet(0);
  } else if (seat_up<0) {
      if (long_ir>400 || irA==1 || irB ==1) {
        wiggle(); 
        delay_before_next=0;
      }
      toilet(1);
    }

  Serial.print(long_ir); 
    delay(delay_before_next);

    
}

