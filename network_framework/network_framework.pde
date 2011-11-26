/*
 Network Client for RiverStream
 with json output.
 
 created 14 November 2011
 by Jakub Oboza
 
 */

#include <SPI.h>
#include <Ethernet.h>

#define DEBUG
#define MAX_OUT_CHARS 64
// server api port
#define PORT 8000
// timespan between updates
#define POSTING_INTERVAL 10000

// ethernet mac address
byte mac[] = { 
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED};
// our ip address (device address in local network)
byte ip[] = { 192, 168, 0, 67 };
// address of local network gateway
byte gateway[] = { 192, 168, 0, 1}; 
// sub network address
byte subnet[] = { 255, 255, 255, 0 };

//  The address of server we are connecting to
byte server[] = { 192, 168, 0, 3 }; 
// initialize the library instance:
Client client(server, PORT);
//buffer used to store data we gone send (+1 is for trailing 0)
char   buffer[MAX_OUT_CHARS + 1];  

long lastConnectionTime = 0;        // last time you connected to the server, in milliseconds
boolean lastConnected = false;      // state of the connection last time through the main loop
const int postingInterval = POSTING_INTERVAL;   //delay between updates

void debug_setup(){
#ifdef DEBUG
  Serial.begin(9600);
#endif
}

void debug(char* info){
#ifdef DEBUG
  Serial.println(info);
#endif
}


void setup() {
  // start the ethernet connection and serial port:
  Ethernet.begin(mac, ip);
  debug_setup();
  // give the ethernet module time to boot up:
  delay(1000);
}

void loop() {
  // read the analog sensor:
  /*
  
  IMPORTANT PART HERE
  read your sensors and put it into buffor
  
  */
  int tempReading = 21; //analogRead(A0);   
  int humReading  = 13; //analogRead(A1);
  
  sprintf(buffer,"{\"temp\": %d, \"hum\":%d}",tempReading, humReading);

  /*
   
  Buffor ready ! thats it :)
   
  */

  // only if debug show incoming stuff on serial port
  #ifdef DEBUG
  if (client.available()) {
    char c = client.read();
    Serial.print(c);
  }
  #endif

  // if there's no net connection, but there was one last time
  // through the loop, then stop the client:
  if (!client.connected() && lastConnected) {
    debug("disconnecting.");
    client.stop();
  }

  // Post data to server
  if(!client.connected() && (millis() - lastConnectionTime > postingInterval)) {
    sendData(buffer);
  }
  // store the state of the connection for next time through
  lastConnected = client.connected();
}

// this method makes a HTTP connection to the server:
void sendData(char* thisData) {
    
  // if there's a successful connection:
  if (client.connect()) {
    debug("connecting...");
    // send the HTTP PUT request. 
    // fill in your feed address here:
    client.print("PUT /api/data.json HTTP/1.1\n");
    // host
    client.print("Host: localhost\n");
    // api key
    client.print("X-RiverStreamApiKey: 001PROTOTYPE\n");
    client.print("Content-Length: ");
    int thisLength = strlen(thisData);
    client.println(thisLength, DEC);
    client.print("Content-Type: application/json\n");
    client.println("Connection: close\n");
    client.println(thisData);
    lastConnectionTime = millis();
  } 
  else {
    debug("connection failed");
    client.stop();
    Client client(server, PORT);
    setup();
    client.flush();
  }
}

