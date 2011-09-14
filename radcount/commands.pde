void processCommand(char* cmd, unsigned len) {
  unsigned long tmp;

  switch(cmd[0]) {
  case 'd':
  case 'D':
    // get/set date.
    if (len > 1) {
      Serial.println("command not implemented");
    }
    tmp = readDate();
    printDate(tmp);
    break;

  case 't':
  case 'T':
    // get/set time.    
    if (len > 1) {
      Serial.println("command not implemented");
    }
    tmp = readTime();
    printTime(tmp);
    break;

  case 'o':
  case 'O':
    // osr   
    if (len > 1) {
      tmp = strToInt(&cmd[1],len-1);
      if (tmp == 32 || tmp == 64 || tmp == 128 || tmp == 255) {
        SetOSR(tmp);
        Serial.print("set osr ");
        Serial.println(tmp, DEC);
      }
      else {
        Serial.println("invalid value");
      }
    }
    break;

  case 'm':
  case 'M':
    // set min pulse threshold.     
    if (len > 1) {
      tmp = strToInt(&cmd[1],len-1);
      setMinPulse(tmp);
    }
    Serial.print("min pulse 0x");
    Serial.println(tmp,HEX);
    break;

  case 'l':
  case 'L':
    // ls
    Serial.println("command not implemented");
    break;

  case 'c':
  case 'C':
    // cp
    Serial.println("command not implemented");
    break;

  case 'r':
  case 'R':
    // rm
    Serial.println("command not implemented");
    break;

  case 'x':
  case 'X':
    shutdown();
    break;
    
  default:
    Serial.println("invalid command");
  }
}

unsigned long strToInt(char * str, unsigned len) {
  if (str[0] == 'x')
    return hexToInt(&str[1], len-1);

  unsigned long result = 0;
  for (int i=0; i < len; ++i) {
    int digit = 0;  
    if (str[i] >= '0' && str[i] <= '9') {
      digit = str[i] - '0';
    }
    result += digit*pow(10,len-1-i);
  }
  return result;
}


unsigned long hexToInt(char * str, unsigned len) {
  unsigned long result = 0;
  for (int i=0; i < len; ++i) {
    int digit = 0;  
    if (str[i] >= '0' && str[i] <= '9') {
      digit = str[i] - '0';
    }
    if (str[i] >= 'A' && str[i] <= 'F') {
      digit = str[i] - 'A' + 10;
    }
    if (str[i] >= 'a' && str[i] <= 'f') {
      digit = str[i] - 'a' + 10;
    }
    result += digit*pow(10,len-1-i);

  }
  return result;
}


