# Helper modules

#======================================================Evaluasi Forecast========================================================#

# Langkah estimasi forecast pakai panel VAR

# 1. Estimasi model Panel VAR Fixed Effect OLS
# 2. Lakukan diagnostik model seperti pada papernya Michael Sigmunda & Robert Ferstlb
# 2. Extract Koefisien
# 3. Extract komponen fixed effect
# 4. Buat interval band pakai bootstrap_irf, pastikan n.ahead sama dengan periode waktu yang ingin diforecast
# 5. Forecast PDRB Nganjuk dengan mengalikan koefisien dengan nilai2 asli, gunakan standard error CI dari bootstrap
# 6. Iterasi langkah ke 5 sampai n.ahead (periode n ke depan)

# Kode Kabupaten/Kota Nganjuk adalah 3518

evaluasi_pvar = function(pdrb_jatim_input, nhor_input) {
  
  if (is.integer(nhor_input)==FALSE) {
    stop('nhor_input seharusnya bilang bulat/integer positif')
  }
  
  if (round(nhor_input, 0) > 3 | round(nhor_input, 0) < 1) {
    stop('nhor_input hanya diperbolehkan minimal bernilai 1 dan maksimal bernilai 3')
  }
  
  jenis_pdrb = unique(pdrb_jatim_input$`Lapangan Usaha`)
  # Filter hanya PDRB total; Pertanian, Kehutanan, dan Perikanan; Industri Pengolahan
  filtered_pdrb = pdrb_jatim_input %>%
    filter(`Lapangan Usaha`==jenis_pdrb[1] | `Lapangan Usaha`==jenis_pdrb[3] | `Lapangan Usaha`==jenis_pdrb[14]) %>%
    mutate(`Lapangan Usaha`=ifelse(`Lapangan Usaha`==jenis_pdrb[1], 'pdrb_total', `Lapangan Usaha`)) %>%
    mutate(`Lapangan Usaha`=ifelse(`Lapangan Usaha`==jenis_pdrb[3], 'industri_pengolahan', `Lapangan Usaha`)) %>%
    mutate(`Lapangan Usaha`=ifelse(`Lapangan Usaha`==jenis_pdrb[14], 'pertanian_dll', `Lapangan Usaha`))
  
  lapangan_usaha_jatim = unique(filtered_pdrb$`Lapangan Usaha`)
  tahun_awal = colnames(filtered_pdrb)[3]
  tahun_akhir = tail(colnames(filtered_pdrb),1)
  
  for (l in lapangan_usaha_jatim) {
    
    # l = 'industri_pengolahan'
    lu_df = filtered_pdrb %>%
      filter(`Lapangan Usaha`==l)
    
    long_df = lu_df %>% 
      pivot_longer(
        cols = `tahun_awal`:`tahun_akhir`, 
        names_to = "tahun",
        values_to = l
      )
    
    
    if (l==lapangan_usaha_jatim[1]) {
      panelvar_df = long_df
    } else {
      series_lu = long_df[l]
      panelvar_df = cbind(panelvar_df, series_lu)
    }
    
  }
  panelvar_df = select(panelvar_df, -2)
  panelvar_df$log_pdrb_total = log(panelvar_df$pdrb_total)
  panelvar_df$log_industri_pengolahan = log(panelvar_df$industri_pengolahan)
  panelvar_df$log_pertanian_dll = log(panelvar_df$pertanian_dll)
  colnames(panelvar_df)[colnames(panelvar_df) == "Nama Kab/Kota"] = "nama_wilayah"
  
  # Merge dengan kode wilayah BPS
  kode_wilayah = read_excel('Data/kode wilayah BPS.xlsx')
  merged_df_inner = inner_join(panelvar_df, kode_wilayah, by = "nama_wilayah")
  merged_df_inner$tahun = as.integer(merged_df_inner$tahun)
  merged_df_inner = merged_df_inner %>%
    mutate(pdrb_growth = log_pdrb_total - lag(log_pdrb_total),
           industri_growth = log_industri_pengolahan - lag(log_industri_pengolahan),
           pertanian_growth = log_pertanian_dll - lag(log_pertanian_dll))
  
  #===================================Evaluasi In-Sample dan Out-Sample============================#
  tahun = unique(merged_df_inner$tahun)
  
  lag_input = 1
  n_ahead_forecast = nhor_input
  in_sample_length = length(tahun) - n_ahead_forecast
  in_sample_tahun = tahun[1:in_sample_length]
  out_sample_tahun = tahun[(in_sample_length+1):length(tahun)]
  
  in_sample_df = merged_df_inner %>% filter(tahun<out_sample_tahun[1])
  out_sample_df = merged_df_inner %>% filter(tahun>=out_sample_tahun[1])
  
  var_feols = 
    pvarfeols(dependent_vars = c('log_pdrb_total', 'log_industri_pengolahan', 'log_pertanian_dll'),
              lags = lag_input,
              transformation = 'demean',
              data = in_sample_df,
              panel_identifier = c('kode_wilayah', 'tahun'))
  
  dep_log = c('log_pdrb_total', 'log_industri_pengolahan', 'log_pertanian_dll')
  
  var_gmm <- pvargmm(dependent_vars = dep_log, # bisa diganti jadi dep_log atau dep_growth
                     lags = lag_input,
                     transformation = "fod",
                     data = in_sample_df,
                     panel_identifier=c("kode_wilayah", "tahun"),
                     steps = c("twostep"),
                     system_instruments = FALSE,
                     max_instr_dependent_vars = 5,
                     max_instr_predet_vars = 2,
                     collapse = TRUE
  )
  
  # Creating forecast function manually from var_gmm
  fe_ex1 = fixedeffects(var_gmm)
  coef_ex1 = coef(var_gmm)
  resid = residuals_level(var_gmm)
  
  # In-Sample Evaluation
  colnames(resid)[3:ncol(resid)] = c('resid_log_pdrb_total', 'resid_log_industri_pengolahan', 'resid_log_pertanian_dll')
  in_sample_merge = merge(in_sample_df, resid, by.x = c('kode_wilayah', 'tahun'), by.y = c('category', 'period'))
  in_sample_merge$fitted_pdrb_total = exp((in_sample_merge$log_pdrb_total + in_sample_merge$resid_log_pdrb_total))
  in_sample_merge$fitted_industri_pengolahan = exp((in_sample_merge$log_industri_pengolahan + in_sample_merge$resid_log_industri_pengolahan))
  in_sample_merge$fitted_pertanian_dll = exp((in_sample_merge$log_pertanian_dll + in_sample_merge$resid_log_pertanian_dll))
  in_sample_ng = in_sample_merge %>% filter(kode_wilayah==3518)
  in_sample_ng_export = in_sample_ng[c('kode_wilayah', 'tahun', 'nama_wilayah', 'pdrb_total', 'industri_pengolahan', 'pertanian_dll',
                                       'fitted_pdrb_total', 'fitted_industri_pengolahan', 'fitted_pertanian_dll')]
  write_xlsx(in_sample_ng_export, 'Export/Evaluasi In-Sample Forecast PanelVAR Nganjuk.xlsx')
  
  # Out-Sample Evaluation
  dependent_vars = dep_log # bisa diganti jadi dep_log atau dep_growth
  
  newdata_id = merged_df_inner %>%
    filter(kode_wilayah == 3518) %>%
    select(all_of(dependent_vars))
  
  resid = residuals_level(var_gmm)
  resid_id = resid %>%
    filter(category == 3518) %>%
    select(all_of(dependent_vars))
  
  original_data = out_sample_df %>% filter(kode_wilayah==3518)
  original_data = original_data[c('nama_wilayah', 'tahun', 'pdrb_total', 'industri_pengolahan', 'pertanian_dll')]
  
  lower_bound_c = c()
  upper_bound_c = c()
  mean_forecast_c = c()
  horizon_c = c()
  
  for (f in 1:n_ahead_forecast) {
    
    indep1 = lag(newdata_id[,1],lag_input)
    indep2 = lag(newdata_id[,2],lag_input)
    indep3 = lag(newdata_id[,3],lag_input)
    index_id = which(unique(merged_df_inner$kode_wilayah)==3518)
    
    target_forecast_list = list()
    predict_list = list()
    
    for (i in 1:length(dependent_vars)) {
      target_forecast = coef_ex1[i,1]*indep1[length(indep1)] + coef_ex1[i,2]*indep2[length(indep2)] + coef_ex1[i,3]*indep3[length(indep3)]
      target_forecast_fe = target_forecast + fe_ex1[[index_id]][i]
      colname_i = dependent_vars[i]
      target_forecast_list[[colname_i]] = target_forecast_fe
      
      # Prediction interval using "Naive Forecast" Method
      st_dev = sd(resid_id[,i], na.rm = TRUE)
      ruas_kanan = f*(1+f/length(indep1))
      st_dev_h = st_dev * sqrt(ruas_kanan)
      lower_bound = target_forecast_fe - st_dev_h*1.96 # 95% Confidence Interval
      upper_bound = target_forecast_fe + st_dev_h*1.96 # 95% Confidence Interval
      lower_bound_c = c(lower_bound_c, lower_bound)
      upper_bound_c = c(upper_bound_c, upper_bound)
      mean_forecast_c = c(mean_forecast_c, target_forecast_fe)
      
      out_sample_tahun_f = out_sample_tahun[f]
      horizon_c = c(horizon_c, out_sample_tahun_f)
      
    }
    newdata_id = rbind(newdata_id, target_forecast_list)
    
    predict_df = data.frame(dep_var = dependent_vars,
                            low_bound = exp(lower_bound_c),
                            mean_forecast = exp(mean_forecast_c),
                            up_bound = exp(upper_bound_c),
                            tahun_fcst = horizon_c)
    
  }
  
  mean_fcst_list = list()
  lower_fcst_list = list()
  upper_fcst_list = list()
  
  for (p in 1:length(unique(predict_df$tahun_fcst))) {
    
    y = unique(predict_df$tahun_fcst)[p]
    predict_df_y = predict_df %>% filter(tahun_fcst==y)
    
    mean_fcst_y = predict_df_y$mean_forecast
    mean_fcst_list[[p]] = mean_fcst_y
    
    lower_fcst_y = predict_df_y$low_bound
    lower_fcst_list[[p]] = lower_fcst_y
    
    upper_fcst_y = predict_df_y$up_bound
    upper_fcst_list[[p]] = upper_fcst_y
  }
  
  mean_fcst_df = do.call(rbind, mean_fcst_list)
  colnames(mean_fcst_df) = c('mean_fcst_pdrb_total', 'mean_fcst_industri_pengolahan', 'mean_fcst_pertanian_dll')
  mean_fcst_export = cbind(original_data, mean_fcst_df)
  
  lower_fcst_df = do.call(rbind, lower_fcst_list)
  colnames(lower_fcst_df) = c('lower_fcst_pdrb_total', 'lower_fcst_industri_pengolahan', 'lower_fcst_pertanian_dll')
  lower_fcst_export = cbind(original_data, lower_fcst_df)
  
  upper_fcst_df = do.call(rbind, upper_fcst_list)
  colnames(upper_fcst_df) = c('upper_fcst_pdrb_total', 'upper_fcst_industri_pengolahan', 'upper_fcst_pertanian_dll')
  upper_fcst_export = cbind(original_data, upper_fcst_df)
  export_fcst_list = list(lower_fcst_export, mean_fcst_export, upper_fcst_export)
  
  write_xlsx(export_fcst_list, 'Export/Evaluasi Out-Sample Forecast PanelVAR Nganjuk.xlsx')
  
  return_object = list(in_sample_ng_export ,export_fcst_list)
  names(return_object) = c('In-Sample Evaluation', 'Out-Sample Evaluation')
  
  return(return_object)
  
}


# Bayesian Global VAR based on paper from Maximilian Boeck; Martin Feldkircher; Florian Huber
# citation: Boeck, M., Feldkircher, M. and Huber, F. (2022). BGVAR: Bayesian Global Vector Autoregressions with Shrinkage Priors in R. Journal of Statistical Software, 104(9). doi:https://doi.org/10.18637/jss.v104.i09.
# link: https://doi.org/10.18637/jss.v104.i09


evaluasi_bgvar = function(pdrb_jatim_input, nhor_input) {
  
  if (is.integer(nhor_input)==FALSE) {
    stop('nhor_input seharusnya bilang bulat/integer positif')
  }
  
  if (round(nhor_input, 0) > 3 | round(nhor_input, 0) < 1) {
    stop('nhor_input hanya diperbolehkan minimal bernilai 1 dan maksimal bernilai 3')
  }
  
  # pdrb_jatim_input = pdrb_jatim
  # nhor_input=2
  jenis_pdrb = unique(pdrb_jatim_input$`Lapangan Usaha`)
  
  # Filter hanya PDRB total; Pertanian, Kehutanan, dan Perikanan; Industri Pengolahan
  
  filtered_pdrb = pdrb_jatim_input %>%
    filter(`Lapangan Usaha`==jenis_pdrb[1] | `Lapangan Usaha`==jenis_pdrb[3] | `Lapangan Usaha`==jenis_pdrb[14]) %>%
    mutate(`Lapangan Usaha`=ifelse(`Lapangan Usaha`==jenis_pdrb[1], 'pdrb_total', `Lapangan Usaha`)) %>%
    mutate(`Lapangan Usaha`=ifelse(`Lapangan Usaha`==jenis_pdrb[3], 'industri_pengolahan', `Lapangan Usaha`)) %>%
    mutate(`Lapangan Usaha`=ifelse(`Lapangan Usaha`==jenis_pdrb[14], 'pertanian_dll', `Lapangan Usaha`))
  
  # Persiapan data panelvar
  lapangan_usaha_jatim = unique(filtered_pdrb$`Lapangan Usaha`)
  tahun_awal = colnames(filtered_pdrb)[3]
  tahun_akhir = tail(colnames(filtered_pdrb),1)
  
  
  for (l in lapangan_usaha_jatim) {
    
    # l = 'industri_pengolahan'
    lu_df = filtered_pdrb %>%
      filter(`Lapangan Usaha`==l)
    
    long_df = lu_df %>% 
      pivot_longer(
        cols = `tahun_awal`:`tahun_akhir`, 
        names_to = "tahun",
        values_to = l
      )
    
    
    if (l==lapangan_usaha_jatim[1]) {
      panelvar_df = long_df
    } else {
      series_lu = long_df[l]
      panelvar_df = cbind(panelvar_df, series_lu)
    }
    
  }
  panelvar_df = select(panelvar_df, -2)
  
  #================================Evalusi In-Sample dan Out-Sample==========================#
  
  # Menyiapkan data untuk bayesian globarvar dalam bentuk list dan w matrix
  singkatan_kota = read_excel('Data/Singkatan Kota.xlsx')
  
  # filter in-sample dan out-sample
  panelvar_df_merge = merge(panelvar_df, singkatan_kota, by.x = "Nama Kab/Kota", by.y = "kotakab")
  panelvar_df_merge$tahun = as.integer(panelvar_df_merge$tahun)
  tahun = unique(panelvar_df_merge$tahun)
  
  n_ahead_forecast = nhor_input
  in_sample_length = length(tahun) - n_ahead_forecast
  in_sample_tahun = tahun[1:in_sample_length]
  out_sample_tahun = tahun[(in_sample_length+1):length(tahun)]
  
  in_sample_df = panelvar_df_merge %>% filter(tahun<out_sample_tahun[1])
  out_sample_df = panelvar_df_merge %>% filter(tahun>=out_sample_tahun[1])
  
  # persiapan data sesuai package globalvar
  entity_kota = unique(panelvar_df_merge$entity)
  
  panelvar_list = list()
  for (k in entity_kota) {
    
    filter_df = panelvar_df_merge %>% filter(entity==k)
    selected_filter = select(filter_df, -1)
    last_slice = ncol(selected_filter)-1
    selected_filter[, 2:last_slice] = lapply(selected_filter[, 2:last_slice], log)
  
    # Convert the year column to Date format (using the first day of each year)
    selected_filter$tanggal = as.Date(paste0(selected_filter$tahun, "-01-01"))

    df_mts = ts(selected_filter[,2:last_slice], start = c(selected_filter$tahun[1], 1), frequency = 1)
  
    panelvar_list[[k]] = df_mts
    
  }
  
  w_matrix = matrix(0, nrow = length(entity_kota), ncol = length(entity_kota))
  rownames(w_matrix) = entity_kota
  colnames(w_matrix) = entity_kota
  
  # Spatial W matrix
  w_inv_dist = read_excel('Data/W_Inv_Dist.xlsx')
  w_std_q = read_excel('Data/W_Standardized_Q.xlsx')
  w_std_r = read_excel('Data/W_Standardized_R.xlsx')
  
  colnames(w_inv_dist)[2:ncol(w_inv_dist)] = entity_kota
  colnames(w_std_q)[2:ncol(w_std_q)] = entity_kota
  colnames(w_std_r)[2:ncol(w_std_r)] = entity_kota
  
  w_inv_dist = column_to_rownames(w_inv_dist, var = 'nama_kab_kota')
  w_std_q = column_to_rownames(w_std_q, var = 'nama_kab_kota')
  w_std_r = column_to_rownames(w_std_r, var = 'nama_kab_kota')
  
  w_inv_dist = as.matrix(w_inv_dist)
  w_std_q = as.matrix(w_std_q)
  w_std_r = as.matrix(w_std_r)
  
  matrix_acuan = w_inv_dist # bisa diganti jadi beberapa opsi seperti w_std_q dan w_std_r
  for (i in rownames(w_matrix)) {
    for (j in colnames(w_matrix)) {
      w_matrix[i,j] = matrix_acuan[i,j]
    }
  }
  
  # Running Bayesian Global VAR
  set.seed(42)
  model_jatim = bgvar(Data = panelvar_list, W = w_matrix)
  yfit_jatim = fitted(model_jatim, global = FALSE)
  
  
  # Evaluasi Forecast
  # In-sample
  yfit_ng = as.data.frame(yfit_jatim[, c('NG.pdrb_total', 'NG.industri_pengolahan', 'NG.pertanian_dll')])
  antilog_ng = exp(yfit_ng)
  antilog_ng$tahun = in_sample_tahun[-1]
  antilog_ng$entity = 'NG'
  colnames(antilog_ng) = c('fitted_pdrb_total', 'fitted_industri_pengolahan', 'fitted_pertanian_dll', 'tahun', 'entity')
  
  insample_ng = in_sample_df %>% filter(entity=='NG')
  insample_ng_merge = inner_join(insample_ng, antilog_ng, by=c('tahun', 'entity'))
  write_xlsx(insample_ng_merge, 'Export/Evaluasi In-Sample Forecast BGVAR Nganjuk.xlsx')
  
  # Out-sample
  fcast_jatim = predict(model_jatim, n.ahead = n_ahead_forecast, global = FALSE)
  
  median_fcast_list = list()
  upper_fcast_list = list()
  lower_fcast_list = list()
  for (n in 1:n_ahead_forecast) {
    
    fcast_ng_n = as.data.frame(fcast_jatim$fcast[c('NG.pdrb_total', 'NG.industri_pengolahan', 'NG.pertanian_dll'),n,])
    median_fcast = fcast_ng_n$Q50
    names(median_fcast) = c('median_fcast_pdrb_total', 'median_fcast_industri_pengolahan', 'median_fcast_pertanian_dll')
    median_fcast_list[[n]] = median_fcast
    
    upper_fcast = fcast_ng_n$Q84
    names(upper_fcast) = c('upper_fcast_pdrb_total', 'upper_fcast_industri_pengolahan', 'upper_fcast_pertanian_dll')
    upper_fcast_list[[n]] = upper_fcast
    
    lower_fcast = fcast_ng_n$Q16
    names(lower_fcast) = c('lower_fcast_pdrb_total', 'lower_fcast_industri_pengolahan', 'lower_fcast_pertanian_dll')
    lower_fcast_list[[n]] = lower_fcast
  }
  
  export_fcast = function(input_list, tahun_vector=out_sample_tahun, df_out_sample=out_sample_df) {
    
    # input_list = lower_fcast_list
    # tahun_vector=out_sample_tahun
    # df_out_sample=out_sample_df
    
    fcast_df = do.call(rbind, input_list)
    fcast = as.data.frame(exp(fcast_df))
    fcast$tahun_fcast = seq(tahun_vector[1], tail(tahun_vector,1))
    out_sample_ng = df_out_sample %>% filter(entity=='NG')
    out_sample_ng = cbind(out_sample_ng, fcast)
    
    return(out_sample_ng)
  }
  
  median_fcast_nganjuk = export_fcast(median_fcast_list)
  lower_fcast_nganjuk = export_fcast(lower_fcast_list)
  upper_fcast_nganjuk = export_fcast(upper_fcast_list)
  out_sample_evaluation = list(lower_fcast_nganjuk, median_fcast_nganjuk, upper_fcast_nganjuk)
  
  write_xlsx(out_sample_evaluation, 'Export/Evaluasi Out-Sample Forecast BGVAR Nganjuk.xlsx')
  
  return_object = list(insample_ng_merge, out_sample_evaluation)
  names(return_object) = c('In-Sample Evaluation', 'Out-Sample Evaluation')
  
  return(return_object)
  
}

# Evaluasi Factor Augmented Time Varying Kernel Regression

evaluasi_favar = function(pdrb_jatim_input, nhor_input) {
  
  if (is.integer(nhor_input)==FALSE) {
    stop('nhor_input seharusnya bilang bulat/integer positif')
  }
  
  if (round(nhor_input, 0) > 3 | round(nhor_input, 0) < 1) {
    stop('nhor_input hanya diperbolehkan minimal bernilai 1 dan maksimal bernilai 3')
  }
  
  # pdrb_jatim_input = pdrb_jatim
  # nhor_input=2
  jenis_pdrb = unique(pdrb_jatim_input$`Lapangan Usaha`)
  
  # Filter hanya PDRB total; Pertanian, Kehutanan, dan Perikanan; Industri Pengolahan
  
  filtered_pdrb = pdrb_jatim_input %>%
    filter(`Lapangan Usaha`==jenis_pdrb[1] | `Lapangan Usaha`==jenis_pdrb[3] | `Lapangan Usaha`==jenis_pdrb[14]) %>%
    mutate(`Lapangan Usaha`=ifelse(`Lapangan Usaha`==jenis_pdrb[1], 'pdrb_total', `Lapangan Usaha`)) %>%
    mutate(`Lapangan Usaha`=ifelse(`Lapangan Usaha`==jenis_pdrb[3], 'industri_pengolahan', `Lapangan Usaha`)) %>%
    mutate(`Lapangan Usaha`=ifelse(`Lapangan Usaha`==jenis_pdrb[14], 'pertanian_dll', `Lapangan Usaha`))
  
  # Persiapan data panelvar
  lapangan_usaha_jatim = unique(filtered_pdrb$`Lapangan Usaha`)
  
  for (l in lapangan_usaha_jatim) {
    
    # l = 'industri_pengolahan'
    lu_df = filtered_pdrb %>%
      filter(`Lapangan Usaha`==l)
    
    long_df = lu_df %>% 
      pivot_longer(
        cols = `2010`:`2022`, 
        names_to = "tahun",
        values_to = l
      )
    
    
    if (l==lapangan_usaha_jatim[1]) {
      panelvar_df = long_df
    } else {
      series_lu = long_df[l]
      panelvar_df = cbind(panelvar_df, series_lu)
    }
    
  }
  panelvar_df = select(panelvar_df, -2)
  
  # Persiapan data FAVAR
  kabkota_jatim = unique(filtered_pdrb$`Nama Kab/Kota`)
  
  for (k in kabkota_jatim) {
    
    # k = 'Nganjuk'
    kabkota_df = panelvar_df %>%
      filter(`Nama Kab/Kota`==k) %>%
      select(-1)
    
    col_indices = 2:4
    names(kabkota_df)[col_indices] = paste0(paste(k, '_', sep = ''), names(kabkota_df)[col_indices])
    
    if (k==kabkota_jatim[1]) {
      favar_df = kabkota_df
    } else {
      kabkota_cbind = select(kabkota_df, -1)
      favar_df = cbind(favar_df, kabkota_cbind)
    }
    
  }
  
  # Transform all columns as logaritma natural, excepts the year column
  original_df = favar_df
  log_favar_df = favar_df[,2:ncol(favar_df)] %>% mutate(across(everything(), log))
  vec_nama_kolom = c('Nganjuk_pdrb_total', 'Nganjuk_pertanian_dll', 'Nganjuk_industri_pengolahan')
  n_ahead_forecast = 2
  tahun = seq(2010, length = nrow(favar_df))
  
  original_df_log = log_favar_df
  list_in_sample_eval = list()
  list_out_sample_eval = list()
  for (c in vec_nama_kolom) {
    
    # c = vec_nama_kolom[1]
    nama_kolom_fsct = c # kolom yang diforecast
    
    # Standardizing data = all variables with mean 0 and standard deviation 1. 
    # This step is crucial in PC analysis
    data_s_log = scale(original_df_log, center = TRUE, scale = TRUE)
    
    # mean and sd of targeted series to forecast
    m_log = mean(original_df_log[,nama_kolom_fsct])
    s_log = sd(original_df_log[,nama_kolom_fsct])
    
    data_s = data_s_log
    s = s_log
    m = m_log
    # Step 1: Extract principal componentes of all X (including Y)
    pc_all = prcomp(data_s, center=FALSE, scale.=FALSE, rank. = 3) 
    res.var = get_pca_var(pc_all)
    contrib = res.var$contrib
    C = pc_all$x # saving the principal components
    
    # Step 2: Clean the PC from the effect of observed Y
    # Next clean the PC of all space from the observed Y
    reg = lm(C ~ data_s[,nama_kolom_fsct])
    F_hat = C - data.matrix(data_s[,nama_kolom_fsct])%*%reg$coefficients[2,] # cleaning and saving F_hat
    
    # Step 3: Estimate Kernel Smoothers
    data_kernel = data.frame(F_hat, nama_kolom_fsct = data_s[,nama_kolom_fsct])
    
    # tvReg OLS
    data_dep = data.matrix(data_kernel$nama_kolom_fsct)
    data_indep = data.matrix(data_kernel[,1:3])
    
    # Estimate initial bandwidth
    bw_number = bw(x=data_indep, y = data_dep, cv.block=0,
                   est='ll', tkernel='Gaussian')
    data_kernel = data_kernel %>% mutate(PC1_lag = lag(PC1, 1),
                                         PC2_lag = lag(PC2, 1),
                                         PC3_lag = lag(PC3, 1))
    
    in_sample_length = nrow(data_kernel) - n_ahead_forecast
    in_sample_df = data_kernel[1:in_sample_length,]
    
    tv_LM = tvLM(nama_kolom_fsct ~ PC1_lag + PC2_lag + PC3_lag, data=in_sample_df, bw=bw_number)
    coef_tvlm = tv_LM$coefficients
    fit_tvlm = tv_LM$fitted
    fit_unscaled = fit_tvlm*s+m
    fit_antilog = exp(fit_unscaled)
    in_sample_ori = original_df[,nama_kolom_fsct][1:in_sample_length]
    nama_kolom_hasil_fcst = paste(nama_kolom_fsct, '_fcst', sep = '')
    in_sample_eval = data_frame(col1=numeric(length(in_sample_ori)),
                                col2=numeric(length(in_sample_ori)),
                                tahun=tahun[1:length(in_sample_ori)])
    in_sample_eval[,1] = in_sample_ori
    in_sample_eval[2:length(in_sample_ori),2] = fit_antilog
    colnames(in_sample_eval) = c(nama_kolom_fsct, nama_kolom_hasil_fcst, 'tahun')
    list_in_sample_eval[[c]] = in_sample_eval
    
    out_sample_length = tail(seq(nrow(data_kernel)), n_ahead_forecast)
    data_baru = cbind(data_kernel$PC1_lag[out_sample_length], data_kernel$PC2_lag[out_sample_length],
                      data_kernel$PC3_lag[out_sample_length])
    fcst = forecast(tv_LM, data_baru, n.ahead=n_ahead_forecast)
    unscaled = fcst * s + m
    antilog = exp(unscaled)
    
    out_sample_ori = original_df[,nama_kolom_fsct][out_sample_length]
    out_sample_eval = data_frame(col1=numeric(length(out_sample_length)),
                                 col2=numeric(length(out_sample_length)),
                                 tahun = tail(tahun, n_ahead_forecast))
    out_sample_eval[,1] = out_sample_ori
    out_sample_eval[,2] = antilog
    colnames(out_sample_eval) = c(nama_kolom_fsct, nama_kolom_hasil_fcst, 'tahun')
    list_out_sample_eval[[c]] = out_sample_eval
    
  }
  
  write_xlsx(list_in_sample_eval, 'Export/Evaluasi In-Sample Forecast FAVAR Nganjuk.xlsx')
  write_xlsx(list_out_sample_eval, 'Export/Evaluasi Out-Sample Forecast FAVAR Nganjuk.xlsx')
  
  return_object = list(list_in_sample_eval, list_out_sample_eval)
  names(return_object) = c('In-Sample Evaluation', 'Out-Sample Evaluation')
  
  return(return_object)
  
}



#=============================================================Direct Forecast=============================================================#
#=============================================================Panel VAR===================================================================#

out_forecast_pvar = function(pdrb_jatim_input, nhor_input) {
  
  if (is.integer(nhor_input)==FALSE) {
    stop('nhor_input seharusnya bilang bulat/integer positif')
  }
  
  if (round(nhor_input, 0) > 7 | round(nhor_input, 0) < 1) {
    stop('nhor_input hanya diperbolehkan minimal bernilai 1 dan maksimal bernilai 7')
  }
  
  jenis_pdrb = unique(pdrb_jatim_input$`Lapangan Usaha`)
  
  # Filter hanya PDRB total; Pertanian, Kehutanan, dan Perikanan; Industri Pengolahan
  filtered_pdrb = pdrb_jatim_input %>%
    filter(`Lapangan Usaha`==jenis_pdrb[1] | `Lapangan Usaha`==jenis_pdrb[3] | `Lapangan Usaha`==jenis_pdrb[14]) %>%
    mutate(`Lapangan Usaha`=ifelse(`Lapangan Usaha`==jenis_pdrb[1], 'pdrb_total', `Lapangan Usaha`)) %>%
    mutate(`Lapangan Usaha`=ifelse(`Lapangan Usaha`==jenis_pdrb[3], 'industri_pengolahan', `Lapangan Usaha`)) %>%
    mutate(`Lapangan Usaha`=ifelse(`Lapangan Usaha`==jenis_pdrb[14], 'pertanian_dll', `Lapangan Usaha`))
  
  lapangan_usaha_jatim = unique(filtered_pdrb$`Lapangan Usaha`)
  tahun_awal = colnames(filtered_pdrb)[3]
  tahun_akhir = tail(colnames(filtered_pdrb),1)
  
  for (l in lapangan_usaha_jatim) {
    
    # l = 'industri_pengolahan'
    lu_df = filtered_pdrb %>%
      filter(`Lapangan Usaha`==l)
    
    long_df = lu_df %>% 
      pivot_longer(
        cols = `tahun_awal`:`tahun_akhir`, 
        names_to = "tahun",
        values_to = l
      )
    
    
    if (l==lapangan_usaha_jatim[1]) {
      panelvar_df = long_df
    } else {
      series_lu = long_df[l]
      panelvar_df = cbind(panelvar_df, series_lu)
    }
    
  }
  panelvar_df = select(panelvar_df, -2)
  panelvar_df$log_pdrb_total = log(panelvar_df$pdrb_total)
  panelvar_df$log_industri_pengolahan = log(panelvar_df$industri_pengolahan)
  panelvar_df$log_pertanian_dll = log(panelvar_df$pertanian_dll)
  colnames(panelvar_df)[colnames(panelvar_df) == "Nama Kab/Kota"] = "nama_wilayah"
  
  # Merge dengan kode wilayah BPS
  kode_wilayah = read_excel('Data/kode wilayah BPS.xlsx')
  merged_df_inner = inner_join(panelvar_df, kode_wilayah, by = "nama_wilayah")
  merged_df_inner$tahun = as.integer(merged_df_inner$tahun)
  merged_df_inner = merged_df_inner %>%
    mutate(pdrb_growth = log_pdrb_total - lag(log_pdrb_total),
           industri_growth = log_industri_pengolahan - lag(log_industri_pengolahan),
           pertanian_growth = log_pertanian_dll - lag(log_pertanian_dll))
  
  #===================================Evaluasi In-Sample dan Out-Sample============================#
  tahun = unique(merged_df_inner$tahun)
  
  lag_input = 1
  n_ahead_forecast = nhor_input
  
  var_feols = 
    pvarfeols(dependent_vars = c('log_pdrb_total', 'log_industri_pengolahan', 'log_pertanian_dll'),
              lags = lag_input,
              transformation = 'demean',
              data = merged_df_inner,
              panel_identifier = c('kode_wilayah', 'tahun'))
  
  dep_log = c('log_pdrb_total', 'log_industri_pengolahan', 'log_pertanian_dll')
  
  var_gmm <- pvargmm(dependent_vars = dep_log, # bisa diganti jadi dep_log atau dep_growth
                     lags = lag_input,
                     transformation = "fod",
                     data = merged_df_inner,
                     panel_identifier=c("kode_wilayah", "tahun"),
                     steps = c("twostep"),
                     system_instruments = FALSE,
                     max_instr_dependent_vars = 5,
                     max_instr_predet_vars = 2,
                     collapse = TRUE
  )
  
  # Creating forecast function manually from var_gmm
  fe_ex1 = fixedeffects(var_gmm)
  coef_ex1 = coef(var_gmm)
  resid = residuals_level(var_gmm)
  
  # Direct Forecast
  dependent_vars = dep_log # bisa diganti jadi dep_log atau dep_growth
  
  newdata_id = merged_df_inner %>%
    filter(kode_wilayah == 3518) %>%
    select(all_of(dependent_vars))
  
  resid = residuals_level(var_gmm)
  resid_id = resid %>%
    filter(category == 3518) %>%
    select(all_of(dependent_vars))
  
  out_sample_tahun = (tail(tahun, 1)+1) + seq(0, n_ahead_forecast - 1)
  
  lower_bound_c = c()
  upper_bound_c = c()
  mean_forecast_c = c()
  horizon_c = c()
  
  for (f in 1:n_ahead_forecast) {
    
    indep1 = lag(newdata_id[,1],lag_input)
    indep2 = lag(newdata_id[,2],lag_input)
    indep3 = lag(newdata_id[,3],lag_input)
    index_id = which(unique(merged_df_inner$kode_wilayah)==3518)
    
    target_forecast_list = list()
    predict_list = list()
    
    for (i in 1:length(dependent_vars)) {
      target_forecast = coef_ex1[i,1]*indep1[length(indep1)] + coef_ex1[i,2]*indep2[length(indep2)] + coef_ex1[i,3]*indep3[length(indep3)]
      target_forecast_fe = target_forecast + fe_ex1[[index_id]][i]
      colname_i = dependent_vars[i]
      target_forecast_list[[colname_i]] = target_forecast_fe
      
      # Prediction interval using "Naive Forecast" Method
      st_dev = sd(resid_id[,i], na.rm = TRUE)
      ruas_kanan = f*(1+f/length(indep1))
      st_dev_h = st_dev * sqrt(ruas_kanan)
      lower_bound = target_forecast_fe - st_dev_h*1.96 # 95% Confidence Interval
      upper_bound = target_forecast_fe + st_dev_h*1.96 # 95% Confidence Interval
      lower_bound_c = c(lower_bound_c, lower_bound)
      upper_bound_c = c(upper_bound_c, upper_bound)
      mean_forecast_c = c(mean_forecast_c, target_forecast_fe)
      
      out_sample_tahun_f = out_sample_tahun[f]
      horizon_c = c(horizon_c, out_sample_tahun_f)
      
    }
    newdata_id = rbind(newdata_id, target_forecast_list)
    
    nama_rows = c('pdrb_total', 'industri_pengolahan', 'pertanian_dll')
    predict_df = data.frame(dep_var = nama_rows,
                            low_bound = exp(lower_bound_c),
                            mean_forecast = exp(mean_forecast_c),
                            up_bound = exp(upper_bound_c),
                            tahun_fcst = horizon_c)
  }
  
  write_xlsx(predict_df, 'Export/Hasil Forecast PanelVAR Direct Out-Sample Nganjuk.xlsx')
  fcst_result = predict_df
  
  return(fcst_result)
}

#=============================================================Bayesian GLOBAL VAR===================================================================#


out_forecast_bgvar = function(pdrb_jatim_input, nhor_input) {
  
  if (is.integer(nhor_input)==FALSE) {
    stop('nhor_input seharusnya bilang bulat/integer positif')
  }
  
  if (round(nhor_input, 0) > 7 | round(nhor_input, 0) < 1) {
    stop('nhor_input hanya diperbolehkan minimal bernilai 1 dan maksimal bernilai 7')
  }
  
  
  jenis_pdrb = unique(pdrb_jatim$`Lapangan Usaha`)
  
  # Filter hanya PDRB total; Pertanian, Kehutanan, dan Perikanan; Industri Pengolahan
  
  filtered_pdrb = pdrb_jatim %>%
    filter(`Lapangan Usaha`==jenis_pdrb[1] | `Lapangan Usaha`==jenis_pdrb[3] | `Lapangan Usaha`==jenis_pdrb[14]) %>%
    mutate(`Lapangan Usaha`=ifelse(`Lapangan Usaha`==jenis_pdrb[1], 'pdrb_total', `Lapangan Usaha`)) %>%
    mutate(`Lapangan Usaha`=ifelse(`Lapangan Usaha`==jenis_pdrb[3], 'industri_pengolahan', `Lapangan Usaha`)) %>%
    mutate(`Lapangan Usaha`=ifelse(`Lapangan Usaha`==jenis_pdrb[14], 'pertanian_dll', `Lapangan Usaha`))
  
  # Persiapan data panelvar
  lapangan_usaha_jatim = unique(filtered_pdrb$`Lapangan Usaha`)
  tahun_awal = colnames(filtered_pdrb)[3]
  tahun_akhir = tail(colnames(filtered_pdrb),1)
  
  
  for (l in lapangan_usaha_jatim) {
    
    # l = 'industri_pengolahan'
    lu_df = filtered_pdrb %>%
      filter(`Lapangan Usaha`==l)
    
    long_df = lu_df %>% 
      pivot_longer(
        cols = `tahun_awal`:`tahun_akhir`, 
        names_to = "tahun",
        values_to = l
      )
    
    
    if (l==lapangan_usaha_jatim[1]) {
      panelvar_df = long_df
    } else {
      series_lu = long_df[l]
      panelvar_df = cbind(panelvar_df, series_lu)
    }
    
  }
  panelvar_df = select(panelvar_df, -2)
  
  # Direct Forecast tanpa melakukan evaluasi
  # Menyiapkan data untuk bayesian globarvar dalam bentuk list dan w matrix
  singkatan_kota = read_excel('Data/Singkatan Kota.xlsx')
  
  # filter in-sample dan out-sample
  panelvar_df_merge = merge(panelvar_df, singkatan_kota, by.x = "Nama Kab/Kota", by.y = "kotakab")
  panelvar_df_merge$tahun = as.integer(panelvar_df_merge$tahun)
  daftar_tahun = unique(panelvar_df_merge$tahun)
  
  # jumlah periode forecast
  n_ahead_forecast = nhor_input
  
  # persiapan data sesuai package globalvar
  entity_kota = unique(panelvar_df_merge$entity)
  
  panelvar_list = list()
  for (k in entity_kota) {
    
    filter_df = panelvar_df_merge %>% filter(entity==k)
    selected_filter = select(filter_df, -1)
    last_slice = ncol(selected_filter)-1
    selected_filter[, 2:last_slice] = lapply(selected_filter[, 2:last_slice], log)
  
    # Convert the year column to Date format (using the first day of each year)
    selected_filter$tanggal = as.Date(paste0(selected_filter$tahun, "-01-01"))

    df_mts = ts(selected_filter[,2:last_slice], start = c(selected_filter$tahun[1], 1), frequency = 1)
  
    panelvar_list[[k]] = df_mts
    
  }
  
  w_matrix = matrix(0, nrow = length(entity_kota), ncol = length(entity_kota))
  rownames(w_matrix) = entity_kota
  colnames(w_matrix) = entity_kota
  
  # Spatial W matrix
  library(tibble)
  w_inv_dist = read_excel('Data/W_Inv_Dist.xlsx')
  w_std_q = read_excel('Data/W_Standardized_Q.xlsx')
  w_std_r = read_excel('Data/W_Standardized_R.xlsx')
  
  colnames(w_inv_dist)[2:ncol(w_inv_dist)] = entity_kota
  colnames(w_std_q)[2:ncol(w_std_q)] = entity_kota
  colnames(w_std_r)[2:ncol(w_std_r)] = entity_kota
  
  w_inv_dist = column_to_rownames(w_inv_dist, var = 'nama_kab_kota')
  w_std_q = column_to_rownames(w_std_q, var = 'nama_kab_kota')
  w_std_r = column_to_rownames(w_std_r, var = 'nama_kab_kota')
  
  w_inv_dist = as.matrix(w_inv_dist)
  w_std_q = as.matrix(w_std_q)
  w_std_r = as.matrix(w_std_r)
  
  matrix_acuan = w_inv_dist # bisa diganti jadi beberapa opsi seperti w_std_q dan w_std_r
  for (i in rownames(w_matrix)) {
    for (j in colnames(w_matrix)) {
      w_matrix[i,j] = matrix_acuan[i,j]
    }
  }
  
  # Running Bayesian Global VAR
  set.seed(42)
  model_jatim_direct = bgvar(Data = panelvar_list, W = w_matrix)
  fcast_jatim_direct = predict(model_jatim_direct, n.ahead = n_ahead_forecast, global = FALSE)
  
  # Export hasil forecast
  median_fcast_list = list()
  upper_fcast_list = list()
  lower_fcast_list = list()
  for (n in 1:n_ahead_forecast) {
    
    fcast_ng_n = as.data.frame(fcast_jatim_direct$fcast[c('NG.pdrb_total', 'NG.industri_pengolahan', 'NG.pertanian_dll'),n,])
    median_fcast = fcast_ng_n$Q50
    names(median_fcast) = c('median_fcast_pdrb_total', 'median_fcast_industri_pengolahan', 'median_fcast_pertanian_dll')
    median_fcast_list[[n]] = median_fcast
    
    upper_fcast = fcast_ng_n$Q84
    names(upper_fcast) = c('upper_fcast_pdrb_total', 'upper_fcast_industri_pengolahan', 'upper_fcast_pertanian_dll')
    upper_fcast_list[[n]] = upper_fcast
    
    lower_fcast = fcast_ng_n$Q16
    names(lower_fcast) = c('lower_fcast_pdrb_total', 'lower_fcast_industri_pengolahan', 'lower_fcast_pertanian_dll')
    lower_fcast_list[[n]] = lower_fcast
  }
  
  out_sample_tahun = (tail(daftar_tahun, 1)+1) + seq(0, n_ahead_forecast - 1)
  export_fcast_direct = function(input_list, tahun_vector=out_sample_tahun) {
    
    fcast_df = do.call(rbind, input_list)
    fcast = as.data.frame(exp(fcast_df))
    fcast$tahun_fcast = tahun_vector
    out_sample_ng = fcast
    
    return(out_sample_ng)
  }
  
  median_fcast_nganjuk = export_fcast_direct(median_fcast_list)
  lower_fcast_nganjuk = export_fcast_direct(lower_fcast_list)
  upper_fcast_nganjuk = export_fcast_direct(upper_fcast_list)
  
  forecast_result = list(lower_fcast_nganjuk, median_fcast_nganjuk, upper_fcast_nganjuk)
  write_xlsx(setNames(forecast_result, names(forecast_result)), 'Export/Hasil Forecast BGVAR Direct Out-Sample Nganjuk.xlsx')
  fcst_result = forecast_result
  
  return(fcst_result)
}


