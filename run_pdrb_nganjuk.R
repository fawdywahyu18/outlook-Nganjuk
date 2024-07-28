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


# Rekomendasi: Folder sebaiknya diletakkan di folder 'Documents', sehingga setting directory sebaiknya dilakukan ke folder "Documents"
# Contoh : 'C:/Users/User/Documents/outlook-Nganjuk-main'
wd = ''
setwd(wd)
pdrb_jatim = read_excel('Data/PDRB Jawa Timur Lapangan Usaha 2010 2022.xlsx') # Data yang selalu diupdate berdasarkan ketersediaan data
set.seed(42)
source('helper.R')


hasil_eval_pvar = suppressWarnings({evaluasi_pvar(pdrb_jatim_input = pdrb_jatim, 2L)})
hasil_eval_bgvar = suppressWarnings({evaluasi_bgvar(pdrb_jatim_input = pdrb_jatim, 2L)})
hasil_eval_favar = suppressWarnings({evaluasi_favar(pdrb_jatim_input = pdrb_jatim, 2L)})
out_fcst_pvar = suppressWarnings({out_forecast_pvar(pdrb_jatim_input = pdrb_jatim, 5L)})
out_fcst_bgvar = suppressWarnings({out_forecast_bgvar(pdrb_jatim_input = pdrb_jatim, 5L)})
