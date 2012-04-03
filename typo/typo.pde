#define NUMWIRES 22

int cn[NUMWIRES] = {
//00  1   2   3   4   5   6   7   8   9  10
  4, 75, A0, A1, A2, A3, A4, A5, 52, 29, 43,
  53, 10, 39, 47, 77, 17, 16, 76, 19, 18 };     // A15 also available (CN12)
//11  12  13  14  15  16  17  18  19  20  21
int group[NUMWIRES];
int queue[NUMWIRES];

//other inputs: 81,82,83

#define NUMKEYS 47
char key[NUMKEYS] = {
  '`','1','2','3','4','5','6','7','8','9','0','-','=',
  'q','w','e','r','t','y','u','i','o','p','[',']','\\',
  'a','s','d','f','g','h','j','k','l',';','\'',
  'z','x','c','v','b','n','m',',','.','/'};
int pins2keys[NUMWIRES][NUMWIRES];
/* #define NUMOUT 8
 int outputs[NUMOUT] = {  5, 6, 7, 8, 79, 9, 78, 80 }; */

void setup() {

  CNPUE = 0x3FFFFF;
  for (int i=0; i <  NUMWIRES; ++i) {
    pinMode(cn[i],INPUT);
    digitalWrite(cn[i],HIGH);
    group[i] = -1;
    queue[i] = -1;
    for (int j=0; j <  NUMWIRES; ++j) {
      pins2keys[i][j] = -1;
    }
  }
  group[0] = 0;
  queue[0] = 0;

  Serial.begin(9600);
  Serial.println("Scanning for groups");
}

void loop() {
  if (!groups_done()) {
    while (scan_for_groups());  
  }
  else {
    for (int i=0; i <  NUMWIRES; ++i) {
      Serial.print("Press: ");
      Serial.print(key[i]);
      while (!scan_for_letter(key[i]) && Serial.read() != 'n') ;
    }  
    for (int i=0; i <  NUMWIRES; ++i) {
      for (int j=0; j <  NUMWIRES; ++j) {
        Serial.print(pins2keys[i][j]);
      }
    }
  }
}

boolean groups_done() {
  for (int i=0; i < NUMWIRES; ++i) {
    if (group[i] == -1)
      return false;
  }
  print_groups();
  return true;
}

void print_groups() {
  for (int i=0; i < NUMWIRES; ++i) {
    Serial.print(group[i]);
    Serial.print(' ');
  }
  Serial.println();
}

boolean scan_for_groups() {

  boolean active = false;
  for (int i=0; i < NUMWIRES; ++i) {
    if (group[i] == -1)
      continue;

    pinMode(cn[i],OUTPUT);
    digitalWrite(cn[i],LOW);
    for (int j=i+1; j < NUMWIRES; ++j) {
      if (digitalRead(cn[j]) == 0) {
        if (group[j] == -1) {
          
          Serial.print("Output, low: pin ");
          Serial.println(cn[i]);
    
          Serial.print("Input low: pin ");
          Serial.println(cn[j]);
        
          active = true;
          group[j] = !group[i];    
          print_pin(j);
          print_groups();
        }
      }

    }
    pinMode(cn[i],INPUT);
    digitalWrite(cn[i],HIGH);
  }
  return active;
}

boolean scan_for_letter(int idx) {
  for (int i=0; i < NUMWIRES; ++i) {
    if (group[i] == -1)
      continue;
    pinMode(cn[i],OUTPUT);
    digitalWrite(cn[i],LOW);
    for (int j=i+1; j < NUMWIRES; ++j) {
      if (digitalRead(cn[j]) == 0) {
        if (pins2keys[i][j] == -1) {
          pins2keys[i][j] = idx; 
          print_pin(i);   
          print_pin(j);
          return true;

        }
      }
    }
    pinMode(cn[i],INPUT);
    digitalWrite(cn[i],HIGH);
  }

  return false;
}
void print_pin(int idx) {
  Serial.print(idx);
  Serial.print(' ');
  Serial.print(group[idx]);
  Serial.print(' ');

  if (cn[idx] >= A0 && cn[idx] <= A15) {
    Serial.print('A');
    Serial.println(cn[idx] - A0,DEC);
  }
  else {
    Serial.println(cn[idx]);
  }
}

