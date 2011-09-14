#define MAX_16_BIT 0xFFFF
#define MIN_SN 1 // the number of the next filename it will write
                  // since the act of programming clears the "EEPROM"

void generateFilename(char * filename) {

  unsigned long sn = MAX_16_BIT;
  int i = 0;

  while ( sn == MAX_16_BIT && i < 512) {
    sn = ( (unsigned)EEPROM.read(i+1) << 8 ) | EEPROM.read(i);
    i += 2;
  }
  sn += MAX_16_BIT*(i/2-1) + 1;
  if (sn < MIN_SN) sn = MIN_SN;
  
  EEPROM.write(i-2,sn);
  EEPROM.write(i-1,sn >> 8);
  sn %= 100000000;
  sprintf(filename, "%08lu.rad", sn);
}


#if 1
void debugsetup() {
  for (int i=0; i < 512; ++i) {
    EEPROM.write(i,0);
  }
  //printEEPROM();
}

void printEEPROM() {
  int i = 0;
  while ( i < 512) {
    unsigned val = ( (unsigned)EEPROM.read(i+1) << 8 ) | EEPROM.read(i);
    Serial.print(i);
    Serial.print("\t");
    Serial.println(val);
    i += 2;
  }
}

#endif
