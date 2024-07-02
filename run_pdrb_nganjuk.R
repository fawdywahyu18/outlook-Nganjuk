library(readxl)
library(dplyr)
library(tidyr)
library(panelvar)
library(writexl)
library(BGVAR)
library(xts)
library(zoo)
library(tibble)
library(tvReg)
library(factoextra)

set.seed(42)
wd = ''
setwd(wd)
pdrb_jatim = read_excel('Data/PDRB Jawa Timur Lapangan Usaha 2010 2022.xlsx') # Data yang selalu diupdate berdasarkan ketersediaan data
source('Code/helper.R')

hasil_eval_pvar = evaluasi_pvar(pdrb_jatim_input = pdrb_jatim, 2L)
hasil_eval_bgvar = evaluasi_bgvar(pdrb_jatim_input = pdrb_jatim, 2L)
hasil_eval_favar = evaluasi_favar(pdrb_jatim_input = pdrb_jatim, 2L)
out_fcst_pvar = out_forecast_pvar(pdrb_jatim_input = pdrb_jatim, 5L)
out_fcst_bgvar = out_forecast_bgvar(pdrb_jatim_input = pdrb_jatim, 5L)
