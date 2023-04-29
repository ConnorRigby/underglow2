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
#define CH2_NRZ_Pin GPIO_PIN_1
#define CH2_NRZ_GPIO_Port GPIOA
#define CH2_EN_Pin GPIO_PIN_2
#define CH2_EN_GPIO_Port GPIOA
#define CH1_EN_Pin GPIO_PIN_3
#define CH1_EN_GPIO_Port GPIOA
#define RF69_NSS_Pin GPIO_PIN_4
#define RF69_NSS_GPIO_Port GPIOA
#define RF69_SCK_Pin GPIO_PIN_5
#define RF69_SCK_GPIO_Port GPIOA
#define RF69_MISO_Pin GPIO_PIN_6
#define RF69_MISO_GPIO_Port GPIOA
#define CH1_R_Pin GPIO_PIN_7
#define CH1_R_GPIO_Port GPIOA
#define RF69_NRESET_Pin GPIO_PIN_0
#define RF69_NRESET_GPIO_Port GPIOB
#define CH2_R_Pin GPIO_PIN_1
#define CH2_R_GPIO_Port GPIOB
#define HCI_RX_Pin GPIO_PIN_10
#define HCI_RX_GPIO_Port GPIOB
#define HCI_TX_Pin GPIO_PIN_11
#define HCI_TX_GPIO_Port GPIOB
#define HCI_RTS_Pin GPIO_PIN_12
#define HCI_RTS_GPIO_Port GPIOB
#define HCI_CTS_Pin GPIO_PIN_13
#define HCI_CTS_GPIO_Port GPIOB
#define CH1_G_Pin GPIO_PIN_14
#define CH1_G_GPIO_Port GPIOB
#define CH1_B_Pin GPIO_PIN_15
#define CH1_B_GPIO_Port GPIOB
#define DI1_Pin GPIO_PIN_6
#define DI1_GPIO_Port GPIOC
#define DI1_EXTI_IRQn EXTI9_5_IRQn
#define DI2_Pin GPIO_PIN_8
#define DI2_GPIO_Port GPIOA
#define DI2_EXTI_IRQn EXTI9_5_IRQn
#define DI3_Pin GPIO_PIN_9
#define DI3_GPIO_Port GPIOA
#define DI3_EXTI_IRQn EXTI9_5_IRQn
#define DI4_Pin GPIO_PIN_15
#define DI4_GPIO_Port GPIOA
#define DI4_EXTI_IRQn EXTI15_10_IRQn
#define CH2_B_Pin GPIO_PIN_10
#define CH2_B_GPIO_Port GPIOC
#define CH2_G_Pin GPIO_PIN_11
#define CH2_G_GPIO_Port GPIOC
#define CH1_NRZ_Pin GPIO_PIN_4
#define CH1_NRZ_GPIO_Port GPIOB
#define RF69_MOSI_Pin GPIO_PIN_5
#define RF69_MOSI_GPIO_Port GPIOB
#define STATUS_LED_GREEN_TX_Pin GPIO_PIN_6
#define STATUS_LED_GREEN_TX_GPIO_Port GPIOB
#define STATUS_LED_YELLOW_RX_Pin GPIO_PIN_7
#define STATUS_LED_YELLOW_RX_GPIO_Port GPIOB
/* USER CODE BEGIN Private defines */

/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
