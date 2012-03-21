#define NUMWIRES 21
int cn[NUMWIRES] = {
  //00   1   2   3   4   5   6   7   8   9  10
  04, 75, A0, A1, A2, A3, A4, A5, 52, 29, 43,
  A15, 10, 53, 47, 77, 17, 16, 76, 19, 18 };     // 39 also available (CN14)
//11   12  13  14  15  16  17  18  19  20
int group[NUMWIRES];
int queue[NUMWIRES];

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
  for (int i=0; i <  NUMWIRES; ++i) {
    pinMode(cn[i],INPUT);
    digitalWrite(cn[i],HIGH);
    group[i] = -1;
    queue[i] = -1;
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
    for (int i =0; i< NUMKEYS; ++i) {
      Serial.print("Press: ");
      Serial.print(key[i]);
      scan_for_letter(key[i]);
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

void scan_for_letter(int idx) {
  boolean active = false;
  for (int i=0; i < NUMWIRES; ++i) {
    if (group[i] == -1)
      continue;
    pinMode(cn[i],OUTPUT);
    digitalWrite(cn[i],LOW);
    for (int j=0; j < NUMWIRES; ++j) {
      if (digitalRead(cn[j]) == 0) {
        active = true;
        if (group[j] == -1) {
          group[j] = !group[i];    
          print_pin(j);
          print_groups();
        }
      }
    }
    pinMode(cn[i],INPUT);
    digitalWrite(cn[i],HIGH);
  }
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



















