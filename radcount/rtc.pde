
/* 
 HACK!
 override these 2 functions to keep bootloader from clobbering our clock!
 */
void RtccSetTimeDate(unsigned long, unsigned long) {
}
PUBLIC rtccRes RtccOpen(unsigned long, unsigned long, int) {
}

#define RTCCLKON RTCCON &(1<<6)

boolean beginRTC(void) {
  /*
	 the SOSCEN bit (OSCCON<1>) must be set (refer to Register 6-1 in Section 6. “Oscillators” (DS61112)) in the
   	 “PIC32 Family Reference Manual” This is the only bit outside of the RTCC module with which
   	 the user must be concerned for enabling the RTCC. The status bit, SOSCRDY (OSCCON<22>),
   	 can be used to check that the Secondary Oscillator (SOSC) is running.
   */
  if  ((OSCCON & (0x1 << 22)) == 0) {
    OSCCON &= (0x1 << 1);         // enable secondary oscillator

    //Serial.println("enabling secondary oscillator");
  }

  if (!(RTCCON & (1<<3))){
    enableWriteRTC();
  }

  if (!RTCCLKON){
    RTCCONSET=0x8000;             // turn on the RTCC
    //Serial.println("turning on RTC");
  }
  while(!(RTCCON&0x40));        // wait for clock to be turned on

  //adjustRTC(__DATE__, __TIME__);
  unsigned long d,t;
  readRTC(&d,&t);
  if (!is_valid(d,t)) {
    adjustRTC(__DATE__, __TIME__);
    //adjustRTC("Jan 01 2000", "12:00:00");
  }
  
  disableWriteRTC();
  return true;
}


void calibrateRTC(int cal) {
  /* The following code example will update the RTCC calibration. */
  //cal=0x3FD; // 10 bits adjustment, -3 in value 
  if(RTCCON&0x8000)
  { // RTCC is ON
    unsigned int t0, t1;
    do
    {
      t0=RTCTIME;
      t1=RTCTIME;
    }
    while(t0!=t1); // read valid time value
    if((t0&0xFF)==00)
    { // we're at second 00, wait auto-adjust to be performed
      while(!(RTCCON&0x2)); // wait until second half...
    }
  }
  RTCCONCLR=0x03FF0000; // clear the calibration
  RTCCONSET=cal;
}

void enableWriteRTC() {
  // assume interrupts are disabled
  // assume the DMA controller is suspended
  // assume the device is locked

  //starting critical sequence

  SYSKEY = 0xaa996655; // write first unlock key to SYSKEY
  SYSKEY = 0x556699aa; // write second unlock key to SYSKEY
  RTCCONSET = 0x8;  // set RTCWREN in RTCCONSET

  //end critical sequence

  SYSKEY = 0x33333333; // device re-lock

  // re-enable interrupts
  // re-enable the DMA controller
}


void disableWriteRTC() {
  RTCCONCLR = 0x8;  // set RTCWREN in RTCCONCLR
}

void adjustRTC(unsigned long date, unsigned long time) {
  /*
     assume the secondary oscillator is enabled and ready, i.e. OSCCON<1>=1, OSCCON<22>=1, 
     and RTCC write is enabled i.e. RTCWREN (RTCCON<3>) =1;
   */
  Serial.println(date, HEX);
  Serial.println(time, HEX);


  RTCCONCLR=0x8000; // turn off the RTCC

  while(RTCCON&0x40) Serial.println("wait for clock to be turned off");

  RTCTIME=time; // safe to update the time
  RTCDATE=date; // update the date
  RTCCONSET=0x8000; // turn on the RTCC

  while(!(RTCCON&0x40)) Serial.println("wait for clock to be turned on");
}

byte bcd2bin(byte val) {
  return val - 6 * (val >> 4);
}

byte bin2bcd (byte val) {
  return val + 6 * (val / 10); 
}


unsigned long readTime() {
  while((RTCCON&0x4)!=0);      // wait for not RTCSYNC
  return RTCTIME;
}

unsigned long readDate() {
  while((RTCCON&0x4)!=0);      // wait for not RTCSYNC
  return RTCDATE;
}

void readRTC(unsigned long *date, unsigned long *time) {
  while((RTCCON&0x4)!=0);      // wait for not RTCSYNC
  *time = RTCTIME;
  *date = RTCDATE;
}

#define SECONDS_FROM_1970_TO_2000 946684800

static uint8_t daysInMonth [] PROGMEM = { 
  31,28,31,30,31,30,31,31,30,31,30,31 };

static uint16_t date2days(uint16_t y, uint8_t m, uint8_t d) {
  if (y >= 2000)
    y -= 2000;
  uint16_t days = d;
  for (uint8_t i = 1; i < m; ++i)
    days += *(daysInMonth + i - 1);
  if (m > 2 && y % 4 == 0)
    ++days;
  return days + 365 * y + (y + 3) / 4 - 1;
}

static long time2long(uint16_t days, uint8_t h, uint8_t m, uint8_t s) {
  return ((days * 24L + h) * 60 + m) * 60 + s;
}


unsigned long unixtime() {
  unsigned long date, time;
  readRTC(&date,&time);
  return unixtime(date,time);
}

unsigned long unixtime(unsigned long date, unsigned long time) {
  byte y = bcd2bin((date & 0xFF000000) >> 24);
  byte m = bcd2bin((date & 0x00FF0000) >> 16);
  byte d = bcd2bin((date & 0x0000FF00) >> 8);

  byte hh = bcd2bin((time & 0xFF000000) >> 24);
  byte mm = bcd2bin((time & 0x00FF0000) >> 16);
  byte ss = bcd2bin((time & 0x0000FF00) >> 8);

  unsigned long t;
  unsigned days = date2days(y, m, d);
  t = time2long(days, hh, mm, ss);
  t += SECONDS_FROM_1970_TO_2000;  // seconds from 1970 to 2000

  return t;
}


byte conv2d(const char* p) {
  byte v = 0;
  if ('0' <= *p && *p <= '9')
    v = *p - '0';
  return 10 * v + *++p - '0';
}


// A convenient constructor for using "the compiler's time":
//   __DATE__, __TIME__
// NOTE: using PSTR would further reduce the RAM footprint
void adjustRTC(const char* date, const char* time) {
  // sample input: date = "Dec 26 2009", time = "12:34:56"
  Serial.println();
  Serial.println("adjusting RTC");
  Serial.println(date);
  Serial.println(time);

  byte yOff = conv2d(date + 9);
  // Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec 
  byte m = 0;
  switch (date[0]) {
  case 'J': 
    m = date[1] == 'a' ? 1 : m = date[2] == 'n' ? 6 : 7; 
    break;
  case 'F': 
    m = 2; 
    break;
  case 'A': 
    m = date[2] == 'r' ? 4 : 8; 
    break;
  case 'M': 
    m = date[2] == 'r' ? 3 : 5; 
    break;
  case 'S': 
    m = 9; 
    break;
  case 'O': 
    m = 10; 
    break;
  case 'N': 
    m = 11; 
    break;
  case 'D': 
    m = 12; 
    break;
  }
  byte d  = conv2d(date + 4);
  byte hh = conv2d(time);
  byte mm = conv2d(time + 3);
  byte ss = conv2d(time + 6);

  unsigned long date_bcd = 1;
  date_bcd |= bin2bcd(yOff) << 24;
  date_bcd |= bin2bcd(m)    << 16;
  date_bcd |= bin2bcd(d)    << 8;

  unsigned long time_bcd = 0;
  time_bcd |= bin2bcd(hh)   << 24;
  time_bcd |= bin2bcd(mm)   << 16;
  time_bcd |= bin2bcd(ss)   << 8;  

  adjustRTC(date_bcd,time_bcd);
}

void printDate(unsigned long date) {
  byte y = bcd2bin((date & 0xFF000000) >> 24);
  byte m = bcd2bin((date & 0x00FF0000) >> 16);
  byte d = bcd2bin((date & 0x0000FF00) >> 8);
  
  char buff[32];
  sprintf(buff, "%u/%u/%u", m,d,y);
  Serial.println(buff);
}

void printTime(unsigned long time) {
  byte hh = bcd2bin((time & 0xFF000000) >> 24);
  byte mm = bcd2bin((time & 0x00FF0000) >> 16);
  byte ss = bcd2bin((time & 0x0000FF00) >> 8);
  
  char buff[32];
  sprintf(buff,  "%u:%u:%u", hh, mm, ss);
  Serial.println(buff);
}

void printTimestamp(unsigned long date, unsigned long time) {
  printDate(date);
  printTime(time);
}

boolean is_valid(unsigned long date, unsigned long time){
  byte y = bcd2bin((date & 0xFF000000) >> 24);
  byte m = bcd2bin((date & 0x00FF0000) >> 16);
  byte d = bcd2bin((date & 0x0000FF00) >> 8);
  
  byte hh = bcd2bin((time & 0xFF000000) >> 24);
  byte mm = bcd2bin((time & 0x00FF0000) >> 16);
  byte ss = bcd2bin((time & 0x0000FF00) >> 8);
  
  if ( y > 99  || m < 1 || m > 12 || d < 1 || d > 31 || hh > 23 || mm > 59 || ss > 59 ) 
    return false;
    
  return true;
}



