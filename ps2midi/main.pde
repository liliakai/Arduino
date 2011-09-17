#include <PS2Keyboard.h>
// PS2 Keyboard MIDI controller
// Connect a PS2 keyboard to pins 3 & 4 (CLK and DATA respectively) 
// and supply 5V to the keyboard  
#define KBD_DATA_PIN A4  
#define KBD_CLK_PIN  19  
#define is_printable(c) (!(c&0x80))   // don't print if top bit is set  

Score score;
PS2Keyboard keyboard;
unsigned long lastkeypress;
unsigned long lastplaytime;
unsigned sampleTempo;
boolean recording;


void setup() {  
  Serial.begin(31250);
  keyboard.begin(KBD_DATA_PIN);  
  score.reset();

  sampleTempo = 200;
  lastkeypress = millis();
  recording = false;
}  


void loop() {  

  if(keyboard.available()) {  
    // reading the "extra" bits is optional  
    byte   extra = keyboard.read_extra(); // must read extra before reading the character byte  
    byte       c = keyboard.read();  

    boolean ctrl = extra & 1;  // <ctrl> is bit 0  
    boolean  alt = extra & 2;  //  <alt> is bit 1  
    boolean shft = extra & 4;
    boolean caps = extra & 8;

    if (!processCmd(ctrl,alt,c)) {   // is it a command?     
      if (recording)
        recordKeyPress(ctrl,alt,c);

      noteOn(score.idx,charToPitch(c),0xFF);
    }
    lastkeypress = millis();
  }     

  if (score.playing && millis() - lastplaytime > sampleTempo) {
    playNext();
    lastplaytime = millis();
  }
}  



void recordKeyPress( boolean ctrl, boolean alt, byte c) {
  if (c == 0x0A) {           // ENTER
    score.seq[score.idx].endLastNote();
  }
  else if (c == ' ') {
    score.add(c,0);
  }
  else if (c == PS2_KC_BKSP) {
    score.deleteNote();
  }
  else if ( is_printable(c) ) {
    byte vel = ~((millis() - lastkeypress) >> 2);
    score.add(charToPitch(c),vel);
  }
}


int processCmd( boolean ctrl, boolean alt, byte key) {
  unsigned temp;
  unsigned long offset = 0;
  static byte n,c = 0;
  switch(key) {
  case ' ':
    if (ctrl){
      score.togglePlayPause();
      break;
    }
    else
      return 0;
  case '\t':
    if (ctrl) {
      score.changeProgram();
      break;
    }
    else 
      return 0;

  case PS2_KC_BKSP:
    if (ctrl) {
      score.deleteNote();
      break;
    }
    else
      return 0; 

  case PS2_KC_UP:
    score.prevSeq();
    break;

  case PS2_KC_DOWN:
    score.nextSeq();
    break;  

  case PS2_KC_LEFT:
    if (sampleTempo > 5)
      sampleTempo-=5;
    break;

  case PS2_KC_RIGHT:
    if (sampleTempo + 5)
      sampleTempo += 5;
    break;

  case 0x0A:            // ENTER
    if (recording) {
      score.seq[score.idx].endLastNote();
      score.seq[score.idx].mute = false;
      recording = false;
    }
    else {
      score.seq[score.idx].mute = true;
      recording = true;
    }

    break;

  case PS2_KC_ESC:
    score.reset();
    break;

  default:
    return 0;
  }
  return 1;
}

void playNext() {
  score.playNext();
}


void noteOn( byte chan, byte key, byte vel) {
  static byte lastNote[MAXVOICES];
  if (!key) {
    noteOff(chan, lastNote[chan]);
    return;
  }

  Serial.write(  0x90 | (chan & 0x0F) );  // note on
  Serial.write( key & 0x7F );             // key
  Serial.write( vel & 0x7F );             // velocity
  lastNote[chan]=key;

}

void noteOff(byte chan, byte key) {
  Serial.write(  0x90 | (chan & 0x0F) );  // note on
  Serial.write( key & 0x7F );             // key
  Serial.write( (uint8_t)0 );             // velocity
}



