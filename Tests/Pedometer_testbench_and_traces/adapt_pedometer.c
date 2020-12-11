/**
@file main.cpp
 
@brief Pedometer implementation using the sensor Triple Axis Accelerometer Breakout - MMA8452Q
 
*/
/**
@file main.h
@brief Header file containing functions prototypes and global variables.
@brief Implementation of a Pedometer using the accelerometer MMA8452Q, Nokia 5110 display and the mbed LPC1768.
@brief Revision 1.5.
@author Edson Manoel da Silva
@date   May 2015
*/
 #define SQRT_MAGIC_F 0x5f3759df 

typedef struct Acceleration Acceleration;
struct Acceleration {
    int x;
    int y;
    int z;
};

Acceleration acceleration;  

/**  
@namespace mma8452
@brief Accleration average structure declared in MMA8452 class
*/
Acceleration acc_avg;

unsigned char second = 0; /*!< second flag set in TimerExpired3 */
unsigned char minute = 0; /*!< minute flag set in TimerExpired3 */
unsigned char hour = 0;/*!< hour flag set in TimerExpired3 */
unsigned char state = 0;/*!< state variable for the FSM */
unsigned char I1_flag = 0;/*!< Interrupt flag set in Transient Detection Interrupt */
unsigned char I2_flag = 0;/*!< Interrupt flag set in Pulse(Tap) Detection Interrupt */
unsigned char timerFlag1 = 0;/*!< Interrupt flag set in Timer1 */
unsigned char timerFlag2 = 0;/*!< Interrupt flag set in Timer2 */
unsigned char aux=0;/*!< Auxiliar for checking if the user stopped using the device */

char Int_SourceSystem =0;/*!< Variable used to read the MMA8452Q Interrupt Source Register */
char Int_SourceTrans=0;/*!< Variable used to clear the MMA8452Q Interrupt Registers */

unsigned char length;/*!< Variable used to check the string length to be printed in the LCD */
char buffer[14];/*!< Buffer used for printing strings on the display */

 int step[16]={};/*!< Variable used to ccalculate the steps */

// int km = 0;/*!< Variable used to ccalculate the kilometers */
int km[16]={};


int acc_vector[16]={};/*!< Variable for check if a step was performed */


int i;
int sub_x;
int sub_y;
int sub_z;
int acceleration_x[16]={};
int acceleration_y[16];
int acceleration_z[16];
int acc_avg_x[16]={};
int acc_avg_y[16];
int acc_avg_z[16];
/**
Set a flag to alert that a Transient Detection Interrupt has ocurred
*/
void Interrupt();

/**
Set a flag to alert that a Pulse Detection Interrupt has ocurred
*/
void Interrupt2();

/**
Blind the LEDS for state machine error alert
*/
void error();

/**
Set a flag to alert that a Timer1 Interrupt has ocurred
*/
void TimerExpired1();

/**
Set a flag to alert that a Timer2 Interrupt has ocurred
*/
void TimerExpired2();

/**
Performs the calculation for the chronometer time
*/
void TimerExpired3();

/**
Saves the data collected in the stepping count to the flash disk
@param date - the date of the data
@param data1 - steps
@param data2 - Kilometer
*/
void writeDataToFile(char *date,int data1,int data2);
int xx=0;
                    int xhalf ;




#define SIZE  10
int n = SIZE;
int A[SIZE][SIZE], B[SIZE][SIZE], C[SIZE][SIZE];
int i,j;

//__attribute__((annotate("step:1,km:1,acc_vector:1"))) 
void pedometer()
{
    /// Finite State Machine that cotrols the whole system
    //Setting the initial state. Avoiding rubish values
    state = 0;
    I1_flag = 0;
    I2_flag = 0;
    
                    aux = 0; 
                    timerFlag2 = 0;

                     for(int i=0;i<16;i++)
                     {    
                         
           #ifdef CGRA_COMPILER
           please_map_me();
           #endif
                        acc_vector[i] = (acceleration_x[i]- acc_avg_x[i]) * (acceleration_x[i]- acc_avg_x[i])+  (acceleration_y[i]- acc_avg_y[i]) * (acceleration_y[i]- acc_avg_y[i])+ (acceleration_z[i]-acc_avg_z[i]) * (acceleration_z[i]-acc_avg_z[i]) ;
                        
                        
                    //     // // If the acceleration vector is greater than 0.15, add the steps
                        if(acc_vector[i]  > 15 && i>1)
                        {
                             step[i] = step[i-1] + 2;
                             // Runing
                             if (acc_vector[i]  > 100)
                                km[i] = km[i-1]+ 2;
                             // Walking
                             else
                                km[i] = km[i-1] + 1;     
                        }



                     }

}



void Interrupt()
{
    /// Controls the Transient Detection Interrupt flag
    I1_flag = 1;
}

void Interrupt2()
{
    /// Controls the Pulse(Tap)Detection Interrupt flag
    I2_flag = 1;
}

void error() 
{
    /// Error function. In case of error of the state machine
//     while(1) 
//     { 
//         lcd.clear();
//         lcd.printString("FSM Error!",0,0);
//     } 
 }

void TimerExpired1()
{
    /// Timer 1 flag
    timerFlag1 = 1;
}

void TimerExpired2()
{
    /// Timer 2 Flag
    timerFlag2 = 1;
}

void TimerExpired3()
{
    /// Calculates the chronometer time
    second = second + 1;
    if (second > 60)
    {
        second = 0;
        minute = minute + 1;
        if (minute > 60)
        {
            hour = hour + 1;
            minute = 0;
        }
   
    }    
}

void writeDataToFile(char *date,int data1,int data2)
{
    /// Saves the km and steps data to flash disk
    // FILE *fp = fopen("/local/log.txt", "a");
    // // Create the txt file
    // fprintf(fp,"Date: %s\n",date);
    // fprintf(fp,"Steps = %6u\n",data1);
    // fprintf(fp,"Km = %6.3f\n \n",data2);
    // fclose(fp);
}

int main(){
 for(int i=0;i<16;i++){    
    sub_x = 0;
    sub_y = 0;
    sub_z = 0;

    acceleration_x[i] = 3*i;
    acceleration_y[i] = 3*i+1;
    acceleration_z[i] = 3*i+2;
    
    acc_avg_x[i] = i;
    acc_avg_y[i] = i;
    acc_avg_z[i] = i;
 }

pedometer();

return 0;
}
