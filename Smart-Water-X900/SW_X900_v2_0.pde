/*  
 *  ------------  [SW_08] - Frame Class Utility  -------------- 
 *  
 *  Explanation: This is the basic code to create a frame with every
 *  Smart Water sensor
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
 *  Version:            0.1
 *  Design:             David Gascón
 *  Implementation:     Luis Miguel Marti
 */
#include <WaspXBee900.h>
#include <WaspSensorSW.h>
#include <WaspFrame.h>

#include <TurbiditySensor.h>
#include <ModbusMaster485.h>
#include <Wasp485.h>

turbiditySensorClass turbiditySensor;

float value_pH;
float value_temp;
float value_pH_calculated;
float value_orp;
float value_orp_calculated;
float value_di;
float value_do;
float value_do_calculated;
float value_cond;
float value_cond_calculated;
//alex
float value_turb; 

// Calibration values
#define cal_point_10 1.985
#define cal_point_7 2.070
#define cal_point_4 2.227
// Temperature at which calibration was carried out
#define cal_temp 23.7
// Offset obtained from sensor calibration
#define calibration_offset 0.0
// Calibration of the sensor in normal air
#define air_calibration 2.65
// Calibration of the sensor under 0% solution
#define zero_calibration 0.0
// Value 1 used to calibrate the sensor
#define point1_cond 10500
// Value 2 used to calibrate the sensor
#define point2_cond 40000
// Point 1 of the calibration 
#define point1_cal 197.00
// Point 2 of the calibration 
#define point2_cal 150.00

char node_ID[] = "S_Water";

pHClass pHSensor;
ORPClass ORPSensor;
DIClass DISensor;
DOClass DOSensor;
conductivityClass ConductivitySensor;
pt1000Class TemperatureSensor;

//Variables for transmission

// Define BROADCAST MAC address
//////////////////////////////////////////
char RX_ADDRESS[] = "000000000000FFFF";
//////////////////////////////////////////

// Define the Waspmote ID
char WASPMOTE_ID[] = "S_Water";

// define variable
uint8_t error;
//End Variables for transmission

void setup() 
{
  USB.ON();
  USB.println(F("Frame Utility Example for Smart Water"));
 // turbiditySensor.ON();

  // Set the Waspmote ID
  frame.setID(node_ID); 
  
  // Configure the calibration values
  pHSensor.setCalibrationPoints(cal_point_10, 
                                cal_point_7, 
                                cal_point_4, 
                                cal_temp);
  DOSensor.setCalibrationPoints(air_calibration, zero_calibration);
  ConductivitySensor.setCalibrationPoints(point1_cond, 
                                          point1_cal, 
                                          point2_cond, 
                                          point2_cal);
  
    // init XBee
  xbee900.ON(SOCKET1);
  //not necessary (I'm belive)  
  SensorSW.ON();
  delay(2000);
  turbiditySensor.ON();
  delay(2000);
}

void loop()
{
    // init XBee
 // xbee900.ON();
  
  ///////////////////////////////////////////
  // 1. Turn on the board
  /////////////////////////////////////////// 

  SensorSW.ON();
  delay(2000);
  turbiditySensor.ON();
  delay(2000);

    // Result of the communication
  int result = -1;
  int retries = 0;
  
   ///////////////////////////////////////////////////////////
  // Get Turbidity Measure
  ///////////////////////////////////////////////////////////

  // Initializes the retries counter
  retries = 0;

  // This variable will store the result of the communication
  // result = 0 : no errors 
  // result = 1 : error occurred
  result = -1;

  while ((result !=0) & (retries < 5)) 
  {  
    retries ++;
    result = turbiditySensor.readTurbidity();
    //USB.print(result);
    delay(10);
  }


  delay(500); 


  ///////////////////////////////////////////
  // 2. Read sensors
  ///////////////////////////////////////////  

  // Read the ph sensor
  value_pH = pHSensor.readpH();
  // Convert the value read with the information obtained in calibration
  value_pH_calculated = pHSensor.pHConversion(value_pH,value_temp);
  // Read the temperature sensor
  value_temp = TemperatureSensor.readTemperature();
  // Reading of the ORP sensor
  value_orp = ORPSensor.readORP();
  // Apply the calibration offset
  value_orp_calculated = value_orp - calibration_offset;
  // Reading of the DI sensor
 // value_di = DISensor.readDI();
  // Reading of the ORP sensor
  value_do = DOSensor.readDO();
  // Conversion from volts into dissolved oxygen percentage
  value_do_calculated = DOSensor.DOConversion(value_do);
  // Reading of the Conductivity sensor
 //value_cond = ConductivitySensor.readConductivity();
  // Conversion from resistance into ms/cm
  value_cond_calculated = ConductivitySensor.conductivityConversion(value_cond);
  
  value_turb = turbiditySensor.getTurbidity();
  
     ///////////////////////////////////////////////////////////
  // Print Turbidity Value
  ///////////////////////////////////////////////////////////
  if (result == 0) {
  //  float turbidity = turbiditySensor.getTurbidity();
    USB.print(F("Turbidity value: "));
   // USB.print(turbidity);    
    USB.print(value_turb);    
    USB.println(F(" NTU"));
  } else {
    USB.println(F("Error while reading turbidity sensor"));
  }
  
  
  ///////////////////////////////////////////
  // 3. Turn off the sensors
  /////////////////////////////////////////// 

  SensorSW.OFF();
 turbiditySensor.OFF();

  //wait 2 seconds
  delay(2000);
  ///////////////////////////////////////////
  // 4. Create ASCII frame
  /////////////////////////////////////////// 

  // Create new frame (MAX?_FRAME)
  frame.createFrame(MAX_FRAME);
 // frame.setFrameSize(200);
  
  // Add temperature
  frame.addSensor(SENSOR_WT, value_temp);
  // Add PH
  frame.addSensor(SENSOR_PH, value_pH_calculated);
  // Add ORP value
  frame.addSensor(SENSOR_ORP, value_orp_calculated);
  // Add DI value
 // frame.addSensor(SENSOR_DINA, value_di);
  // Add DO value
  frame.addSensor(SENSOR_DO, value_do_calculated);
  // Add conductivity value
 // frame.addSensor(SENSOR_COND, value_cond_calculated);
 
 // Add TurbiditySensor
  frame.addSensor(SENSOR_TURB, value_turb);

  // Show the frame
  frame.showFrame();

 ///////////////////////////////////////////
  // 2. Send packet
  ///////////////////////////////////////////  

  // send XBee packet
  error = xbee900.send( RX_ADDRESS, frame.buffer, frame.length );   
  
  // check TX flag
  if( error == 0 )
  {
    USB.println(F("send ok"));
  }
  else 
  {
    USB.println(F("send error"));
  }

  //wait 2 seconds
  delay(2000);
}
