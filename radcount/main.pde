#define ADC_RESET_PIN   A6
#define ADC_CS_PIN       4 
#define ADC_DR_PIN       2 
#define CAP_CLEAR       A0
#define KEEP_ALIVE_PIN  33

byte bins[4096];

unsigned long data1;
unsigned long thresh = 0xFFF;
unsigned long starttime;
unsigned long pulsecount;
boolean shutdownflag;

float vsum = 0;
float vcnt = 0;

void setup() {

  pinMode(KEEP_ALIVE_PIN, INPUT);
  while (!digitalRead(KEEP_ALIVE_PIN)) ;

  Serial.begin(2400);

  shutdownflag = false;
  pulsecount = 0;

  beginRTC();

  /* adc setup */
  pinMode(CAP_CLEAR, OUTPUT);          // write high then low to drain capture-and-hold capacitor
  pinMode(ADC_RESET_PIN, OUTPUT);      // adc reset line, must be high
  pinMode(ADC_CS_PIN, OUTPUT);         // adc chip select
  pinMode(ADC_DR_PIN, INPUT);          // adc data ready

  digitalWrite(CAP_CLEAR,LOW);         // clear cap
  digitalWrite(ADC_RESET_PIN, LOW);    // put adc in reset mode
  digitalWrite(ADC_DR_PIN, HIGH);      // pull-up resistor  
  digitalWrite(ADC_RESET_PIN, HIGH);   // MUST BE HIGH FOR mcp3901 TO WORK

  beginADC();
  unsigned long date,time;
  readRTC(&date,&time);
  printTimestamp(date,time);
  unsigned long now = unixtime(date,time); 
  starttime = now;
}

void shutdown() {
  Serial.println("shutting down");

  // shutdown adcs and put mcu to sleep.
  // put adc into "Full Shutdown" mode
  ExtCLK(1);
  ExtVref(1);
  ShutdownADCs(1,1);

  // put mcu to sleep
  OSCCONSET = 0x10;     // set power-save mode to sleep
  asm volatile("wait"); // enter power-save

    // will resume execution here after wake.

  while(!digitalRead(KEEP_ALIVE_PIN));  
  beginADC();
  unsigned long date,time;
  readRTC(&date,&time);
  unsigned long now = unixtime(date,time);
  starttime = now;
  shutdownflag = false;
  pulsecount = 0;
}

void loop() {
  static unsigned long lasttimestamp = 0;
  static unsigned long lastreporttime = 0;
  static unsigned long lastcount = 0;

  // Check for shutdown signal
  if (shutdownflag || !digitalRead(KEEP_ALIVE_PIN)) {
    shutdown();
  }

  // handle serial input
  if (Serial.available()) {
    char c = Serial.read();
    handleCommand(c);
  }

  unsigned long chan1, chan2;
  static int prev = -1;
  int curr = digitalRead(ADC_DR_PIN);
  if (curr != prev) {                            // pin changed ?                
    prev = curr;
    if (curr == LOW) {                           // data ready!
      readADC(&chan1,&chan2);
      if (chan1 > thresh) {
        clearCapacitor();
        handleData(chan1);
        pulsecount++;

        //Serial.println(chan2,HEX);
        vsum += chan2;
        vcnt++;
      }
    }
  }
}

void handleData(unsigned long data) {
  int idx = data >> 20;
  ++bins[idx];
  if (bins[idx] == 255) {
    for (int i =0; i < 4096; ++i) {
      bins[i] /= 2;
    }      
  }
}
void handleCommand(char c) {
  if (c == 'r'){
    //report!
    Serial.write('r');
    for (int i =0; i < 4096; ++i) {
      int val = bins[i];
      Serial.write(val);
      Serial.write(val>>8);
      Serial.write(val>>16);
      Serial.write(val>>24);

      delayMicroseconds(100);  
    }
  }
  else if (c == 'c') {
    // clear data
    for (int i =0; i < 4096; ++i) {
      bins[i] = 0;
      pulsecount = 0;
    }
  }
}
void clearCapacitor(){
  digitalWrite(CAP_CLEAR,HIGH);          
  delay(1);
  digitalWrite(CAP_CLEAR,LOW);
}

void request_shutdown(){
  shutdownflag = true;
}

void setMinPulse(unsigned long t){
  thresh = t;
}

