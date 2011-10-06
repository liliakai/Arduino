#define ADC_RESET_PIN   A6
#define ADC_CS_PIN       4 
#define ADC_DR_PIN       2 
#define CAP_CLEAR       A0
#define KEEP_ALIVE_PIN  33


char FILENAME[32];
byte eofstr[] = {
  0xFF, 'e', 'n', 'd', '!'};
unsigned long data1;
unsigned long thresh = 0xFFF;
unsigned long starttime;
unsigned long pulsecount;
boolean shutdownflag;

#define COMMAND_LEN_MAX 32
char command[COMMAND_LEN_MAX];
int commandLen = 0;

float vsum = 0;
float vcnt = 0;

void setup() {

  pinMode(KEEP_ALIVE_PIN, INPUT);
  while (!digitalRead(KEEP_ALIVE_PIN)) ;

  Serial.begin(2400);
  lcd_clear();

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
  writeTimestamp(now);
  starttime = now;
}


void loop() {
  static unsigned long lasttimestamp = 0;
  static unsigned long lastreporttime = 0;
  static unsigned long lastcount = 0;


  if (Serial.available()) {
    char c = Serial.read();
    if (c == 13 || c == 10) {
      processCommand(command, commandLen);
      commandLen = 0;
    }
    else {
      command[commandLen] = c;
      ++commandLen %= COMMAND_LEN_MAX;
    }
  }

  if (shutdownflag || !digitalRead(KEEP_ALIVE_PIN)) {
    Serial.println("shutting down");

    // shutdown adcs and put mcu to sleep.
    lowPowerMode(); 
    // will resume execution here after wake.

    while(!digitalRead(KEEP_ALIVE_PIN));  
    beginADC();
    unsigned long date,time;
    readRTC(&date,&time);
    unsigned long now = unixtime(date,time);
    writeTimestamp(now);
    starttime = now;
    shutdownflag = false;
    pulsecount = 0;
  }

  unsigned long ts = unixtime();
  unsigned long now = millis();
  if (now >= lasttimestamp + 60000) {
    writeTimestamp(ts);
    lasttimestamp = now;
    lastcount = pulsecount;

    vsum=0; 
    vcnt=0;
  }


  unsigned long chan1, chan2;
  static int prev = -1;
  int curr = digitalRead(ADC_DR_PIN);
  if (curr != prev) {                            // pin changed ?                
    prev = curr;
    if (curr == LOW) {                           // data ready!
      readADC(&chan1,&chan2);
      if (chan1 > thresh) {
        //        while (digitalRead(ADC_DR_PIN) == HIGH); // do we need to wait for it to go low first?
        //        readADC(&chan1);
        clearCapacitor();
        writeData(chan1);
        pulsecount++;

        //Serial.println(chan2,HEX);
        vsum += chan2;
        vcnt++;
      }
    }
  }
}

void clearCapacitor(){
  digitalWrite(CAP_CLEAR,HIGH);          
  delay(1);
  digitalWrite(CAP_CLEAR,LOW);
}

void shutdown(){
  shutdownflag = true;

}
void lowPowerMode() {
  // put adc into "Full Shutdown" mode
  ExtCLK(1);
  ExtVref(1);
  ShutdownADCs(1,1);

  // put mcu to sleep
  OSCCONSET = 0x10;     // set power-save mode to sleep
  asm volatile("wait"); // enter power-save

}

void setMinPulse(unsigned long t){
  thresh = t;
}


void writeData(unsigned long data) {
  Serial.println(data);
}

void writeTimestamp(unsigned long timestamp) {
  Serial.print("time: ");
  Serial.println(timestamp);
}











