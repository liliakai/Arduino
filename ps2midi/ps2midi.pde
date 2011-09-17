#define BUFFERSIZE 64
#define MAXVOICES 3

typedef struct {
  unsigned long dur; // duration (ms)
  byte key;
  byte vel;
} 
Note;

typedef struct {
  byte chan;
  byte prog;
  boolean mute;
  unsigned len;
  unsigned idx;
  unsigned long t_lastNoteOn;
  unsigned long t_lastNoteAdd;
  Note buffer[BUFFERSIZE];


  void endLastNote() {
    buffer[len-1].dur = millis()-t_lastNoteAdd;
  }

  void add(Note n) {
    unsigned long now = millis();
    if (len < BUFFERSIZE) {
      if (len > 0) {
        buffer[len-1].dur = now-t_lastNoteAdd;
      }
      buffer[len] = n;
      ++len;
      t_lastNoteAdd = now;

    }
  }  

  void deleteNote() {
    if (len) {
      buffer[len-1].key = 0;
      buffer[len-1].vel = 0;
      buffer[len-1].dur = 0;
      --len;
    }
  }

  void playNext() {
    unsigned long now = millis();
    if (now > t_lastNoteOn + buffer[idx].dur) {
      t_lastNoteOn = now;        
      noteOff(chan,buffer[idx].key);
      ++idx %= len;

      if (!mute)
        noteOn(chan,buffer[idx].key,buffer[idx].vel);

      t_lastNoteOn = now;
    }
  }


  void changeProgram() {
    ++prog %= 100;
    Serial.write(0xc0);
    Serial.write(prog);
  }

  void changeChannel() {
    ++chan %= MAXVOICES;
  }


} 
Sequence;

typedef struct {
  unsigned idx;
  unsigned cnt;
  boolean playing;
  Sequence seq[MAXVOICES];

  void add(byte k, byte v) {
    Note n;
    n.key = k;
    n.vel = v;
    seq[idx].add(n);    
  }

  void add(Note n) {
    seq[idx].add(n);   
  }

  void deleteNote() {
    seq[idx].deleteNote();
  }

  void nextSeq() {
    ++idx %= MAXVOICES;   
  }

  void prevSeq() {
    --idx %= MAXVOICES;    
  }


  void playNext() {
    if (!playing)
      return;

    for (int i=0; i < MAXVOICES; ++i) {
      if (seq[i].len) // skip empty sequences
        seq[i].playNext();
    }
  }

  void stopPlaying() {
    for (int i=0; i < MAXVOICES; ++i)
      for (int j=0; j < BUFFERSIZE; ++j)
        noteOff(seq[i].chan,seq[i].buffer[j].key);

  }

  void changeProgram() {
    seq[idx].changeProgram();
  }

  void changeChannel() {
    seq[idx].changeChannel();
  }

  void togglePlayPause() {
    playing = !playing;
    if (playing)
      ;
    else {
      stopPlaying();
    }
  }

  void reset() {
    for (int i=0; i < MAXVOICES; ++i){
      seq[i].len = 0;
      seq[i].chan = i;
    }
  }
} 
Score;
