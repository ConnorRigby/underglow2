/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
  ******************************************************************************
  * @attention
  *
  * <h2><center>&copy; Copyright (c) 2023 STMicroelectronics.
  * All rights reserved.</center></h2>
  *
  * This software component is licensed by ST under BSD 3-Clause license,
  * the "License"; You may not use this file except in compliance with the
  * License. You may obtain a copy of the License at:
  *                        opensource.org/licenses/BSD-3-Clause
  *
  ******************************************************************************
  */
/* USER CODE END Header */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32g4xx_hal.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Exported types ------------------------------------------------------------*/
/* USER CODE BEGIN ET */

/* USER CODE END ET */

/* Exported constants --------------------------------------------------------*/
/* USER CODE BEGIN EC */

/* USER CODE END EC */

/* Exported macro ------------------------------------------------------------*/
/* USER CODE BEGIN EM */

/* USER CODE END EM */

void HAL_TIM_MspPostInit(TIM_HandleTypeDef *htim);

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */

void entry(void);
void entry_error_handler(void);

/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/
#define NRESET_Pin GPIO_PIN_10
#define NRESET_GPIO_Port GPIOG
#define PI1_Pin GPIO_PIN_0
#define PI1_GPIO_Port GPIOA
#define PI2_Pin GPIO_PIN_1
#define PI2_GPIO_Port GPIOA
#define PI3_Pin GPIO_PIN_2
#define PI3_GPIO_Port GPIOA
#define PI4_Pin GPIO_PIN_3
#define PI4_GPIO_Port GPIOA
#define R_PWM_Pin GPIO_PIN_4
#define R_PWM_GPIO_Port GPIOA
#define G_PWM_Pin GPIO_PIN_6
#define G_PWM_GPIO_Port GPIOA
#define B_PWM_Pin GPIO_PIN_1
#define B_PWM_GPIO_Port GPIOB
#define BLE_RX_Pin GPIO_PIN_10
#define BLE_RX_GPIO_Port GPIOB
#define BLE_TX_Pin GPIO_PIN_11
#define BLE_TX_GPIO_Port GPIOB
#define BLE_RTS_Pin GPIO_PIN_12
#define BLE_RTS_GPIO_Port GPIOB
#define BLE_CTS_Pin GPIO_PIN_13
#define BLE_CTS_GPIO_Port GPIOB
#define VCP_TX_Pin GPIO_PIN_9
#define VCP_TX_GPIO_Port GPIOA
#define VCP_RX_Pin GPIO_PIN_10
#define VCP_RX_GPIO_Port GPIOA
#define RX_LED_Pin GPIO_PIN_11
#define RX_LED_GPIO_Port GPIOA
#define TX_LED_Pin GPIO_PIN_12
#define TX_LED_GPIO_Port GPIOA
#define NZR2_Pin GPIO_PIN_6
#define NZR2_GPIO_Port GPIOB
#define NZR1_Pin GPIO_PIN_7
#define NZR1_GPIO_Port GPIOB
/* USER CODE BEGIN Private defines */

/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
