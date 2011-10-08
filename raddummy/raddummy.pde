void setup() {
  Serial.begin(115200);
}

void loop() {
  byte in = Serial.read();
  if (in == 'r') {
    Serial.write('r');
    for (int i =0; i < 4096; ++i) {
      int val = i;//random(4096);
      Serial.write(val);
      Serial.write(val>>8);
      delayMicroseconds(50);  
    }
  }
}

