// Serial lcd

#define chr(x) x, BYTE

void lcd_clear() {
  Serial.print(chr(12));
  delay(5);
}

