/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2023 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
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
#include "usbd_cdc_if.h"

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

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */

/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/
#define RADIO_RESET_Pin GPIO_PIN_2
#define RADIO_RESET_GPIO_Port GPIOA
#define RADIO_IRQ_Pin GPIO_PIN_3
#define RADIO_IRQ_GPIO_Port GPIOA
#define RADIO_IRQ_EXTI_IRQn EXTI3_IRQn
#define RADIO_NSS_Pin GPIO_PIN_4
#define RADIO_NSS_GPIO_Port GPIOA
#define RADIO_SCK_Pin GPIO_PIN_5
#define RADIO_SCK_GPIO_Port GPIOA
#define RADIO_MISO_Pin GPIO_PIN_6
#define RADIO_MISO_GPIO_Port GPIOA
#define RADIO_MOSI_Pin GPIO_PIN_7
#define RADIO_MOSI_GPIO_Port GPIOA
#define SPIFLASH_NSS_Pin GPIO_PIN_12
#define SPIFLASH_NSS_GPIO_Port GPIOB
#define SPIFLASH_SCK_Pin GPIO_PIN_13
#define SPIFLASH_SCK_GPIO_Port GPIOB
#define SPIFLASH_MISO_Pin GPIO_PIN_14
#define SPIFLASH_MISO_GPIO_Port GPIOB
#define SPIFLASH_MOSI_Pin GPIO_PIN_15
#define SPIFLASH_MOSI_GPIO_Port GPIOB
#define RF_TX_Pin GPIO_PIN_5
#define RF_TX_GPIO_Port GPIOB
#define RF_RX_Pin GPIO_PIN_6
#define RF_RX_GPIO_Port GPIOB
#define USB_RX_Pin GPIO_PIN_7
#define USB_RX_GPIO_Port GPIOB
#define USB_TX_Pin GPIO_PIN_8
#define USB_TX_GPIO_Port GPIOB

/* USER CODE BEGIN Private defines */

/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */
