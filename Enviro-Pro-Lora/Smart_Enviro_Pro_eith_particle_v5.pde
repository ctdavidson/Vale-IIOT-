
// Include libraries

#include <WaspFrame.h>
#include <WaspSX1272.h>
#include <WaspOPC_N2.h>
#include <WaspSensorGas_Pro.h>

// Define the Waspmote default ID
char node_id[] = "Tom_0";

// Define the authentication key
char key_access[] = "85045124";

// Declare global variables
//packetXBee* packet;
//char macHigh[10];
//char macLow[11];
char filename[]="TestSD.txt";
uint8_t out0;
uint8_t out1;


// Declare the XBEE_type
// 0 - 802.15.4 
// 1 - 900 MHz - 868 MHz
// 2 - DigiMesh
// 3 - XBee ZB
// 4 - No XBee
// 5 - 900 MHz Intl
int XBEE_type = 5;

// Declare the ZigBee_type, when needed
// 0 - Coordinator API
// 1 - Router API
// 2 - other
int ZIGBEE_type = 0;

// Declare the LoRa_type
boolean LoRa_type = true;


// Each object will be used by each gas sensor
Gas CO(SOCKET_A);
Gas O3(SOCKET_B);
Gas SO2(SOCKET_C);
Gas NO2(SOCKET_F);


float conc_CO;		// Stores the concentration level of CO in ppm
float conc_O3;		// Stores the concentration level of O3 in ppm
float conc_SO2;		// Stores the concentration level of SO2 in ppm
float conc_NO2;		// Stores the concentration level of NO2 in ppm
float temperature;	// Stores the temperature in ºC
float humidity;		// Stores the realitve humidity in %RH
float pressure;		// Stores the pressure in Pa

int status;
int measure;


void setup()
{

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




  /////////////////////////////////
  // 5. LEDs management 
  /////////////////////////////////  
  Utils.setLED(LED0, LED_OFF);
  Utils.setLED(LED1, LED_OFF);
  for (int i = 0 ; i < 4 ; i++)
  {
    Utils.blinkLEDs(100);
  }

  /////////////////////////////////
  // 7. Get the XBee firmware version
  /////////////////////////////////   
 
    if ( XBEE_type = 5){
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


 
    USB.OFF();
  
}


void loop()
{
  // set Green LED
  Utils.setLED(LED1,LED_ON);
    ///////////////////////////////////////////
    // 1a. Turn on particle sensor
    ///////////////////////////////////////////  

    // Power on the OPC_N2 sensor. 
    // If the gases PRO board is off, turn it on automatically.
    status = OPC_N2.ON();
    if (status == 1)
    {
        USB.println(F("Particle sensor started"));

    }
    else
    {
        USB.println(F("Error starting the particle sensor"));
    }

    ///////////////////////////////////////////
    // 1b. Read the particle sensor
    ///////////////////////////////////////////  

    if (status == 1)
    {
        // Power the fan and the laser and perform a measure of 8 seconds
        measure = OPC_N2.getPM(8000);
        if (measure == 1)
        {
            USB.println(F("Measure performed"));
            USB.print(F("PM 1: "));
            USB.print(OPC_N2._PM1);
            USB.println(F(" ug/m3"));
            USB.print(F("PM 2.5: "));
            USB.print(OPC_N2._PM2_5);
            USB.println(F(" ug/m3"));
            USB.print(F("PM 10: "));
            USB.print(OPC_N2._PM10);
            USB.println(F(" ug/m3"));
        }
        else
        {
            USB.print(F("Error performing the measure. Error code:"));
            USB.println(measure, DEC);
        }
    }
  
  
  
    ///////////////////////////////////////////
    // 1c. Turn off the particle sensor
    /////////////////////////////////////////// 
    // Power off the OPC_N2 sensor. If there aren't other sensors powered, 
    // turn off the board automatically
    OPC_N2.OFF();

    delay(15000);
   // delay(1500);

    ///////////////////////////////////////////
    // 2a. Turn on gas sensors
    /////////////////////////////////////////// 

    // Power on the sensors. 
    // If the gases PRO board is off, turn it on automatically.
    CO.ON();
    O3.ON();
    SO2.ON();
    NO2.ON();

    // The sensor needs time to warm up and get a response from gas
    // To reduce the battery consumption, use deepSleep instead delay
    // After 2 minutes, Waspmote wakes up thanks to the RTC Alarm
  //  PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
    PWR.deepSleep("00:00:00:10", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);

  
  
  
    ///////////////////////////////////////////
    // 2b. Read gas sensors
    ///////////////////////////////////////////  
    // Read the sensors and compensate with the temperature internally
    conc_CO = CO.getConc();
    conc_O3 = O3.getConc();
    conc_SO2 = SO2.getConc();
    conc_NO2 = NO2.getConc();

    // Read enviromental variables
    // In this case, CO objet has been used.
    // O3, SO2 or NO2 objects could be used with the same result
    temperature = CO.getTemp();
    humidity = CO.getHumidity();
    pressure = CO.getPressure();

    // And print the values via USB
    USB.println(F("***************************************"));
    USB.print(F("CO concentration: "));
    USB.print(conc_CO);
    USB.println(F(" ppm"));
    USB.print(F("O3 concentration: "));
    USB.print(conc_O3);
    USB.println(F(" ppm"));
    USB.print(F("SO2 concentration: "));
    USB.print(conc_SO2);
    USB.println(F(" ppm"));
    USB.print(F("NO2 concentration: "));
    USB.print(conc_NO2);
    USB.println(F(" ppm"));
    USB.print(F("Temperature: "));
    USB.print(temperature);
    USB.println(F(" Celsius degrees"));
    USB.print(F("RH: "));
    USB.print(humidity);
    USB.println(F(" %"));
    USB.print(F("Pressure: "));
    USB.print(pressure);
    USB.println(F(" Pa"));  
  
    // 2c. Turn off the gas sensors
// Power off the sensors sensor. If there aren't more gas sensors powered, 
    // turn off the board automatically
    CO.OFF();
    O3.OFF();
    SO2.OFF();
    NO2.OFF();

  
  
  ////////////////////////////////////////////////
  // 9. Message composition
  ////////////////////////////////////////////////

  // 9.1 Create new frame (No mote id)
  frame.setID(node_id);
  frame.createFrame(ASCII);  
//  frame.addSensor(SENSOR_ACC, ACC.getX(), ACC.getY(), ACC.getZ() );
//  frame.addSensor(SENSOR_IN_TEMP, RTC.getTemperature());
//  frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel());

     // Add CO concentration
    frame.addSensor(SENSOR_GP_CO, conc_CO);
    // Add O3 concentration
    frame.addSensor(SENSOR_GP_O3, conc_O3);
    // Add SO2 concentration
    frame.addSensor(SENSOR_GP_SO2, conc_SO2);
    // Add NO2 concentration
    frame.addSensor(SENSOR_GP_NO2, conc_NO2);
    // Add temperature
    frame.addSensor(SENSOR_GP_TC, temperature);
    // Add humidity
    frame.addSensor(SENSOR_GP_HUM, humidity);
    // Add pressure
    frame.addSensor(SENSOR_GP_PRES, pressure);	
    // Add PM 1
    frame.addSensor(SENSOR_OPC_PM1,OPC_N2._PM1); 
    // Add PM 2.5
    frame.addSensor(SENSOR_OPC_PM2_5,OPC_N2._PM2_5); 
    // Add PM 10
    frame.addSensor(SENSOR_OPC_PM10,OPC_N2._PM10); 
    // Add PM 10
    frame.addSensor(SENSOR_BAT,PWR.getBatteryLevel()); 

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
