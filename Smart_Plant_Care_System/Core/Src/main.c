/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2026 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <stdio.h>
#include "motor.h"
#include "soil_sensor.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
#define PORT GPIOA
#define PIN GPIO_PIN_1
#define HUMIDITY_MAX 80
#define SOIL_MOISTURE_MAX 80
#define SOIL_MOISTURE_MIN 50
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
/*
 * PIN ASSIGNEMNTS
 * PA1 = TEMPERATURE / HUMIDITY SENSOR IN
 * PA6 = WATER PUMP SINGAL OUT
 */
uint8_t Humidity_b1, Humidity_b2, Temp_byte1, Temp_byte2;
uint16_t SUM, RH, TEMP;
uint8_t pumpStatus, motorStatus;
uint8_t waterEventCheck = 0;
uint8_t needWater;
uint32_t soilMoisture;

volatile uint8_t enclosureOpen = 1;
volatile uint32_t ms_ticks = 0;

//void SysTick_Handler(void)
//{
//	ms_ticks++;
//}
void systick_init(void) {
    *(volatile uint32_t*)0xE000E014 = 15999;
    *(volatile uint32_t*)0xE000E018 = 0;
    *(volatile uint32_t*)0xE000E010 = 7;
}

void delayMicroseconds (uint16_t time)
{
	TIM6->CNT = 0;
	while(TIM6->CNT < time);
}

void TIM5_IRQHandler(void) //60s Timer Interrupt handler -- EVALUATION TIMER
{
	TIM5->SR &= ~TIM_SR_UIF; 				//Clear Interrupt Flag
	waterEventCheck = 1;
}

void TIM2_IRQHandler(void) //30s timer interrupt handler - end of window
{
	TIM2->SR &= ~TIM_SR_UIF;    //Clear Interrupt Flag
	pumpStatus = 0;  			//Turn off water pump
	TIM2->CR1 &= ~TIM_CR1_CEN; //STOP 30S TIMER
}


float Temperature = 0;
float Humidity = 0;
uint8_t ACK = 0;

void Set_Pin_Output (void)
{
	GPIOA->MODER &= ~0x0000000C; //CLEAR PA1 MODE
	GPIOA->MODER |=  0x00000004;  //SET PA1 AS OUTPUT
}

void Set_Pin_Input (void)
{
	GPIOA->MODER &= ~0x0000000C; //Set PA1 as input
}

void DHT_Start (void)
{
	Set_Pin_Output ();  // set the pin as output
	GPIOA->BSRR = GPIO_BSRR_BR1; //Host pulls low
	delayMicroseconds (1100);  // Hold low for at least 1ms

	GPIOA->BSRR = GPIO_BSRR_BS1;   // Host pulls up
    delayMicroseconds (20);   // Hold high for min 20us
	Set_Pin_Input();    // set as input
}

uint8_t DHT_ACK (void) //Check if sensor is responding
{
	uint8_t ACK = 0;
	delayMicroseconds (40); //After host pulls line high, wait 40-80ms
	if (!(GPIOA->IDR & GPIO_IDR_ID1))//Check if sensor has pulled line low
	{
		delayMicroseconds (80); //wait again
		if (GPIOA->IDR & GPIO_IDR_ID1) //check if sensor has pulled back high
			ACK = 1;
		else ACK = -1;
	}
	while (GPIOA->IDR & GPIO_IDR_ID1); //hold until data begins (back to low)
	return ACK;
}

uint8_t DHT_Read (void)
{
	uint8_t i,j;
	for (j=0;j<8;j++)
	{
		while (!(GPIOA->IDR & GPIO_IDR_ID1));   // wait for the pin to go high
		delayMicroseconds (40);   // wait for 40 us
		if (!(GPIOA->IDR & GPIO_IDR_ID1))   // if the pin is low
		{
			i&= ~(1<<(7-j));   // write 0
		}
		else i|= (1<<(7-j));  // if the pin is high, write 1
		while (GPIOA->IDR & GPIO_IDR_ID1);  // wait for the pin to go low
	}
	return i;
}

static void MX_TIM2_Init(void) //30 second TIMER CONFIGURATION
{
	RCC->APB1ENR |= RCC_APB1ENR_TIM2EN;			//enable TIM2 clock
	TIM2->CR1 = 0;							//Clear CR1 Register
	TIM2->PSC = 16000 - 1;					//Divide down clock with PSC to 1KHZ
	TIM2->ARR = 5000 - 1;					//1Khz = 1ms Period. 30s / 1ms = 30000 Ticks
	TIM2->EGR = TIM_EGR_UG;					//Event Generate Update
	TIM2->SR = 0;							//Clear Status Register
	TIM2->DIER |= TIM_DIER_UIE;				//Enable Interrupts
	NVIC_SetPriority(TIM2_IRQn, 3);			//Set Priority 3 (lowest)
	NVIC_EnableIRQ(TIM2_IRQn);				//Enable Interrupt in NVIC
}

static void MX_TIM5_Init(void) //60 second TIMER CONFIGURATION
{
	RCC->APB1ENR |= RCC_APB1ENR_TIM5EN;			//enable TIM2 clock
	TIM5->CR1 = 0;							//Clear CR1 Register
	TIM5->PSC = 16000 - 1;					//Divide down clock with PSC to 1KHZ
	TIM5->ARR = 30000 - 1;					//1Khz = 1ms Period. 60s / 1ms = 60000 Ticks
	TIM5->EGR = TIM_EGR_UG;					//Event Generate Update
	TIM5->SR = 0;							//Clear Status Register
	TIM5->DIER |= TIM_DIER_UIE;				//Enable Interrupts
	NVIC_SetPriority(TIM5_IRQn, 3);			//Set Priority 3 (lowest)
	NVIC_EnableIRQ(TIM5_IRQn);				//Enable Interrupt in NVIC
}

static void MX_TIM6_Init(void)
{
	RCC->APB1ENR |= RCC_APB1ENR_TIM6EN;			//enable TIM2 clock
	TIM6->CR1 = 0;							//Clear CR1 Register
	TIM6->PSC = 16 - 1;					//Divide down clock with PSC to 1KHZ
	TIM6->ARR = 0xffff - 1;					//1Khz = 1ms Period. 60s / 1ms = 60000 Ticks
	TIM6->EGR = TIM_EGR_UG;					//Event Generate Update
	TIM6->SR = 0;							//Clear Status Register
	TIM6->CNT = 0;
	TIM6->CR1 |= TIM_CR1_CEN; //enable  timer

}

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */
	__disable_irq();
  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  /* USER CODE BEGIN 2 */
  MX_TIM2_Init();
  MX_TIM5_Init();
  MX_TIM6_Init();

  soil_init(); //setup soil sensor
  motor_init();//setup motor

  TIM5->CR1 |= TIM_CR1_CEN; //enable 60s timer


  __enable_irq();

  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {

	  if(waterEventCheck) //enabled once 60s timer is up
	  {
		  DHT_Start(); //First, read temperature / humidity
		  ACK = DHT_ACK();

		  Humidity_b1 = DHT_Read();
		  Humidity_b2 = DHT_Read();
		  Temp_byte1 = DHT_Read();
		  Temp_byte2 = DHT_Read();
		  SUM = DHT_Read();

		  TEMP = ((Temp_byte1<<8)| Temp_byte2);
		  RH = ((Humidity_b1<<8)|Humidity_b2);

		  Temperature = (float) ((TEMP / 10) * 1.8 + 32);
		  Humidity = (float) (RH / 10.0);

		  soilMoisture = soil_update();

		  //If Moisture low, humidity low
		  if(Humidity < HUMIDITY_MAX && soilMoisture < SOIL_MOISTURE_MIN)//if no rain detected, turn on pump + start timer
		  {
			  //
			  pumpStatus = 1;
			  motor_start_timed(5);
		  	  TIM2->CNT = 0;
		  	  TIM2->CR1 |= TIM_CR1_CEN; //START 30S TIMER

		  }
		  //Moisture low, humidity high
		  else if (Humidity > SOIL_MOISTURE_MAX && soilMoisture < SOIL_MOISTURE_MIN)
			  {

			  	  pumpStatus = 0; // leave water off the system
			  	  motor_start_timed(5); //open system if not open
			  }
		  //Moisture HIGH, HUMIDITY HIGH
		  else if(Humidity > HUMIDITY_MAX && soilMoisture > SOIL_MOISTURE_MAX)
		  {
			  //Close top + no water
			  pumpStatus = 0;
			  motor_reverse_timed(5); //close system
		  }
		  //Moisture HIGH, Humidity LOW
		  else if (Humidity < HUMIDITY_MAX && soilMoisture > SOIL_MOISTURE_MAX )
		  {
			  pumpStatus = 0; //No water
			  motor_start_timed(5);
			  //
		  }
		  waterEventCheck = 0; //Done checking
	  }

	  if(pumpStatus)
		  GPIOA->BSRR = (1 << 6); //Turn ON Water Pump
	  else if(!pumpStatus)
		  GPIOA->BSRR = (1 << (6+16));//Turn OFF water pump
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
//default clock configuration (16Mhz)
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE3);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_NONE;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_HSI;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */

//Combination of default pin assignments (to button, onboard LED etc. - not used)
//along with specific asignments for our project.
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};
  /* USER CODE BEGIN MX_GPIO_Init_1 */
  //our pin assignments
  RCC->AHB1ENR |= 0x5; //Enable GPIOA + C Clock
  GPIOA->MODER &= ~0xC; //clear PA1 (Set PA1 = Input)
  GPIOA->MODER &= ~0x3000; //clear PA6 mode
  GPIOA->MODER |= (1<<12); //Set PA6 = OUTPUT
  /* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(LD2_GPIO_Port, LD2_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin : B1_Pin */
  GPIO_InitStruct.Pin = B1_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_IT_FALLING;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(B1_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pin : LD2_Pin */
  GPIO_InitStruct.Pin = LD2_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(LD2_GPIO_Port, &GPIO_InitStruct);

  /* USER CODE BEGIN MX_GPIO_Init_2 */

  /* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}
#ifdef USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
