/*
 *  ------Waspmote starting program------
 *
 *  Explanation: Send basic parameters through the corresponding 
 *  XBee module.
 *  For other communication modules please use on line code generator.
 *
 *  Copyright (C) 2015 Libelium Comunicaciones Distribuidas S.L.
 *  http://www.libelium.com
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Version:                0.6
 *  Design:                 David Gascón
 *  Implementation:         Yuri Carmona, Javier Siscart
 */

// Include libraries
#include <WaspXBee802.h>
#include <WaspXBeeZB.h>
#include <WaspXBeeDM.h>
#include <WaspFrame.h>
#include <WaspSX1272.h>
#include <WaspSensorGas_Pro.h>
#include <WaspSensorGas_v20.h>


char  CONNECTOR_A[3] = "CA";      
char  CONNECTOR_B[3] = "CB";    
char  CONNECTOR_C[3] = "CC";
char  CONNECTOR_D[3] = "CD";
char  CONNECTOR_E[3] = "CE";
char  CONNECTOR_F[3] = "CF";

long  sequenceNumber = 0;   
                                               
char  nodeID[10] = "MY_MOTE";   

char* sleepTime = "00:01:23:20";           

char data[100];     

float connectorAFloatValue; 
float connectorBFloatValue;  
float connectorCFloatValue;    
float connectorDFloatValue;   
float connectorEFloatValue;
float connectorFFloatValue;

int connectorAIntValue;
int connectorBIntValue;
int connectorCIntValue;
int connectorDIntValue;
int connectorEIntValue;
int connectorFIntValue;

char  connectorAString[10];  
char  connectorBString[10];   
char  connectorCString[10];
char  connectorDString[10];
char  connectorEString[10];
char  connectorFString[10];

//
Gas CO2(SOCKET_1);
Gas CO(SOCKET_2);
Gas O3(SOCKET_3);
Gas O2(SOCKET_4);
Gas NO(SOCKET_5);
Gas NO2(SOCKET_6);

float temperature; 
float humidity; 
float pressure;
float concCO2;
float concCO;
float concO3;
float concO2;
float concNO;
float concNO2;
//

// Define the Waspmote default ID
char node_id[] = "Tom_Environment_2";

// Define the authentication key
char key_access[] = "85045124";

// Declare global variables
packetXBee* packet;
char macHigh[10];
char macLow[11];
char filename[]="TestSD.txt";
uint8_t out0;
uint8_t out1;

// Broadcast address
uint8_t destination[8]={ 
  0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0xFF};

// PAN ID to set in order to search a new coordinator, in case of ZigBee protocol
uint8_t  PANID[8]={ 
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};

//ATBD7: 7E 00 05 08 01 42 44 07 69
uint8_t ATBD7[9] = {
  0x7E, 0x00, 0x05, 0x08, 0x01, 0x42, 0x44, 0x07, 0x69};

//ATAP2: 7E 00 05 08 01 41 50 02 63
uint8_t ATAP2[9] = {
  0x7E, 0x00, 0x05, 0x08, 0x01, 0x41, 0x50, 0x02, 0x63};

//ATWR: 7E 00 04 08 01 57 52 4D
uint8_t ATWR[8] = {
  0x7E, 0x00, 0x04, 0x08, 0x01, 0x57, 0x52, 0x4D};

// Declare the XBEE_type
// 0 - 802.15.4 
// 1 - 900 MHz - 868 MHz
// 2 - DigiMesh
// 3 - XBee ZB
// 4 - No XBee
// 5 - 900 MHz Intl
int XBEE_type = 5;

// Declare the LoRa_type
boolean LoRa_type = true;


void setup()
{
 CO.ON();
  ///////////////////////////////////////
  // Boards ON       ////////////////////
  ///////////////////////////////////////
  PWR.setSensorPower(SENS_3V3, SENS_ON); 
  
  /////////////////////////////////
  // 1. Test SD
  /////////////////////////////////    
  SD.ON();
  if(digitalRead(SD_PRESENT))
  {
    SD.del(filename);
    SD.create(filename);
    if(SD.writeSD(filename,"Test SD",0))
    {
      USB.println(F("SD OK"));
    }
    else
    {
      USB.println(F("Error SD"));
    }
  }
  else
  {
    USB.println(F("No SD card detected"));
  }
  SD.del(filename);


  /////////////////////////////////
  // 2. Store key access in EEPROM
  /////////////////////////////////
  Utils.setAuthKey(key_access);

  /////////////////////////////////
  // 3. Set up RTC and ACC
  /////////////////////////////////
  delay(500);
  RTC.ON();
  ACC.ON();

  /////////////////////////////////
  // 4. Set Waspmote setting for XBee module for first time.
  // (baudrate at 115200  and API mode enabled)
  ///////////////////////////////// 
  // Note: Only valid for SOCKET 0
  xbee802.ON();
  Utils.setMuxSocket0();
  delay(500);
  beginSerial(9600, 0);
  printString("+++", 0);
  delay(2000);
  printString("ATBD7,AP2,WR,CN\r\n", 0);
  delay(200);

  // 4.1 In case of Zigbee modules:
  for (uint8_t i = 0; i < 9; i++)
  {
    printByte(ATBD7[i], 0);	
  }
  delay(150);  
  closeSerial(0);
  delay(200);
  beginSerial(115200, 0);
  for (uint8_t i = 0; i < 9; i++)
  {
    printByte(ATAP2[i], 0);	
  }
  delay(150);  
  for (uint8_t i = 0; i < 8; i++)
  {
    printByte(ATWR[i], 0);	
  }
  delay(150);  
  closeSerial(0); 


  /////////////////////////////////
  // 5. LEDs management 
  /////////////////////////////////  
  Utils.setLED(LED0, LED_OFF);
  Utils.setLED(LED1, LED_OFF);
  for (int i = 0 ; i < 4 ; i++)
  {
    Utils.blinkLEDs(100);
  }

//  /////////////////////////////////
//  // 6. Get the XBee MAC address
//  /////////////////////////////////  
//  xbee802.OFF();
//  delay(1000);  
//  xbee802.ON();
//  delay(1000);  
//  xbee802.flush();
//
//  // Get the XBee MAC address
//  int counter = 0;
//  while((xbee802.getOwnMac() != 0) && (counter < 12))
//  {   
//    xbee802.getOwnMac();
//    counter++;
//  }
//
//  // convert mac address from array to string
//  Utils.hex2str(xbee802.sourceMacHigh, macHigh, 4);
//  Utils.hex2str(xbee802.sourceMacLow,  macLow,  4);  
//

  /////////////////////////////////
  // 7. Get the XBee firmware version
  /////////////////////////////////   
  int counter = 0; 
  while((xbee802.getSoftVersion() != 0) && (counter < 12))
  {
    xbee802.getSoftVersion();
    counter++;
  } 
    
  // Set the XBee firmware type
  if( (xbee802.softVersion[0] < 0x20) && (xbee802.softVersion[1] > 0x80) )
  {
    XBEE_type = 0; // 802.15.4
  }
  else
  {
    // no XBee, maybe LoRa module
    XBEE_type = 5;
    xbee802.OFF();

    // checking if it is a LoRa module
    sx1272.ON();  
    if( sx1272.getPower() == 0 )
    {
      out0 = sx1272.setLORA();
      out1 = sx1272.setMode(1);
      if( out0 == 0 )
      {
        LoRa_type = true;
      }
    }  
  }


  /////////////////////////////////
  // 8. Print module information
  /////////////////////////////////     
  USB.println(F("\nStarting program by default"));

  if( LoRa_type == true )
  {
    // LoRa_type is TRUE
    USB.println(F("SX1272 module is plugged on socket 0:"));
    if( out1 == 0 )
    {
      USB.println(F("   Configuration:"));
      USB.println(F("     Mode: 1"));
      out0 = sx1272.setChannel(CH_01_900);
      if( out0 == 0 )
      {
        USB.println(F("     Channel: 01_900"));
      }      
      out0 = sx1272.setHeaderON();
      if( out0 == 0 )
      {
        USB.println(F("     Header: ON"));
      }    
      out0 = sx1272.setCRC_ON();
      if( out0 == 0 )
      {
        USB.println(F("     CRC: ON"));
      }  
      out0 = sx1272.setPower('H');
      if( out0 == 0 )
      {
        USB.println(F("     Power: 'H'"));
      }  
      out1 = sx1272.setNodeAddress(3);
      if( out1 == 0 )
      {
        USB.println(F("     Node Address: 3"));
      }
    }
  }


  USB.println();
  USB.println(F("==============================="));


}


void loop()
{
  // set Green LED
  Utils.setLED(LED1,LED_ON);
    //Turn on the sensor board
    SensorGasv20.ON();
  
  ////////////////////////////////////////////////
  // 9. Message composition
  ////////////////////////////////////////////////
   SensorGasv20.readValue(SENS_HUMIDITY);
   connectorBFloatValue = SensorGasv20.readValue(SENS_HUMIDITY);
    //Conversion into a string
   Utils.float2String(connectorBFloatValue, connectorBString, 2);

humidity = CO.getHumidity();

  // 9.1 Create new frame (No mote id)
  frame.setID(node_id);
  frame.createFrame(ASCII);  

  // 9.2 Add frame fields
  frame.addSensor(SENSOR_ACC, ACC.getX(), ACC.getY(), ACC.getZ() );
  frame.addSensor(SENSOR_IN_TEMP, RTC.getTemperature());
  frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel());
  frame.addSensor(SENSOR_GP_HUM, humidity);
  // 9.3 Print frame
  // Example:<=>#35690399##5#MAC:4066EF6B#ACC:-47;-26;1000#IN_TEMP:26.25#BAT:59#
  frame.showFrame();


  ////////////////////////////////////////////////
  // 10. Send the packet
  ////////////////////////////////////////////////

  if( LoRa_type == true )
  {
    out0 = sx1272.sendPacketTimeout(BROADCAST_0, frame.buffer, frame.length);
    if( out0 == 0 )
    {
      USB.println(F("the frame above was sent"));
    }
    else 
    {
      USB.println(F("sending error"));
    } 
  }
  else
  {
    if( XBEE_type == 5 ) 
    {
      USB.println(F("the frame above is printed just by USB (it is not sent because no XBee is plugged)"));  
    }
  }
  delay(5000);
}
