"""
Created on Wed Mar 13 10:50:55 2024

@author: Fawdy
"""

# EJPERBO Edited
import calendar
import requests
import pandas as pd
import numpy as np
import datetime
import time
from tqdm import tqdm

def _time_parse(days, min_date_input, max_date_input):
    
    min_date=min_date_input
    max_date=max_date_input
        
    min_date_l = [int(d) for d in min_date.split("-")]
    max_date_l = [int(d) for d in max_date.split("-")]
    min_date_dt = datetime.date(min_date_l[0], min_date_l[1], min_date_l[2])
    max_date_dt = datetime.date(max_date_l[0], max_date_l[1], max_date_l[2])
    time_dif = max_date_dt-min_date_dt
    num_days = time_dif.days
    if days=="all":
        time_list=[(min_date_dt+datetime.timedelta(i)).strftime("%Y-%m-%d")\
               for i in range(num_days+1)]
    else:
        time_list=[]
        for i in range(num_days+1):
            date=min_date_dt+datetime.timedelta(i)
            if date.strftime("%A") in days:
                time_list.append(date.strftime("%Y-%m-%d"))
    return time_list

def _time_parse_month(min_date_input, max_date_input):
    start_date=int(min_date_input[-2:])
    start_month=int(min_date_input[5:7])
    start_year=int(min_date_input[:4])
    end_date=int(max_date_input[-2:])
    end_month=int(max_date_input[5:7])
    end_year=int(max_date_input[:4])

    year_list=np.arange(start_year, end_year+1, 1)

    months_start_end=[]
    for iy,year in enumerate(year_list):
        if iy==0 and len(year_list)!=1:
            initial_month=start_month
            final_month=12
        elif iy==0 and len(year_list)==1:
            initial_month=start_month
            final_month=end_month
        elif iy!=0 and iy==len(year_list)-1:
            initial_month=1
            final_month=end_month
        else:
            initial_month=1
            final_month=12
        for month in range(initial_month, final_month+1):
            range_mdate = calendar.monthrange(year, month)
            num_dates=range_mdate[1]

            if iy==0 and month==initial_month:
                str_start=datetime.date(year,month,start_date).strftime("%Y-%m-%d")
                str_end=datetime.date(year,month,num_dates).strftime("%Y-%m-%d")
                months_start_end.append((str_start,str_end))
            elif iy==len(year_list)-1 and month==final_month:
                str_start=datetime.date(year,month,1).strftime("%Y-%m-%d")
                str_end=datetime.date(year,month,end_date).strftime("%Y-%m-%d")
                months_start_end.append((str_start,str_end))
            else:
                str_start=datetime.date(year,month,1).strftime("%Y-%m-%d")
                str_end=datetime.date(year,month,num_dates).strftime("%Y-%m-%d")

                months_start_end.append((str_start,str_end))

    return months_start_end

def _market_parse(URL_input, PASAR_ENDPOINT_input, nama_kab, start_date, end_date,
                  init=False):
    
    # region = nama_kab
    with requests.session() as rs:
        rs.get(URL_input)
        rp=rs.get(PASAR_ENDPOINT_input+nama_kab)
    market_names=[rp.json()[i]['psr_nama'] for i in range(len(rp.json()))]
    market_id=[rp.json()[i]['psr_id'] for i in range(len(rp.json()))]
    if init:
        print("SISKAPERBO East Java Python Client (unofficial)")
        print("="*50)
        if nama_kab[-3:] == "kab":
            print("Selected region: ", nama_kab[:-3].capitalize())
        else:
            print("Selected region: ", nama_kab[:-4].capitalize())
        print("Time range: {} - {}".format(start_date, end_date))
        print("Available market: ", market_names)
        market_data=dict(m_names=market_names,m_id=market_id)
    else:
        return dict(m_names=market_names,m_id=market_id)
    
def _single_query(payload, market_data,
                  URL_input="https://siskaperbapo.jatimprov.go.id/harga/tabel", 
                  ENDPOINT_input="https://siskaperbapo.jatimprov.go.id/harga/tabel.nodesign/"):
    
    with requests.session() as rs:
        rs.get(URL_input)
        rp = rs.post(ENDPOINT_input, payload, allow_redirects=False)
        df = pd.read_html(rp.text, thousands='.', decimal=',')
        data=df[0]
        data.columns=["NO","NAMA_BAHAN_POKOK","SATUAN","HARGA_KEMARIN","HARGA_SEKARANG","PERUBAHAN_RP","PERUBAHAN_PERSEN"]
        
        bool_bhn=data['NO'].notnull()
        bhn_name=data['NAMA_BAHAN_POKOK']

        bhn_name_list=[]
        bhn_name_first=bhn_name[0]
        for bobh, bhnm in zip(bool_bhn, bhn_name):
            if bobh:
                bhn_name_first=bhnm
                bhn_name_list.append(bhn_name_first)
            else:
                bhn_name_list.append(bhn_name_first)

        data.replace('-', np.NaN,inplace=True)
        data['NAMA_BAHAN_POKOK'] = data['NAMA_BAHAN_POKOK'].str.replace('- ','',regex=False)
        data['BHN_PKK']=bhn_name_list
        data['BHN_PKK'] = data['BHN_PKK'].str.replace('- ','',regex=False)
        data['SATUAN']=data['SATUAN'].str.lower()

        data['HARGA_KEMARIN'] = data['HARGA_KEMARIN'].astype(str).str.replace('.','',regex=False)
        data['HARGA_SEKARANG'] = data['HARGA_SEKARANG'].astype(str).str.replace('.','',regex=False)
        data['PERUBAHAN_RP'] = data['PERUBAHAN_RP'].astype(str).str.replace('.','',regex=False)
        data['PERUBAHAN_PERSEN'] = data['PERUBAHAN_PERSEN'].astype(str).str.replace('.','', regex=False)
        data['PERUBAHAN_PERSEN'] = data['PERUBAHAN_PERSEN'].astype(str).str.replace(',','.', regex=False)
        data['PERUBAHAN_PERSEN'] = data['PERUBAHAN_PERSEN'].astype(str).str.replace('%','', regex=False)
        
        data[['HARGA_KEMARIN', 'HARGA_SEKARANG','PERUBAHAN_RP','PERUBAHAN_PERSEN']] = \
             data[['HARGA_KEMARIN', 'HARGA_SEKARANG','PERUBAHAN_RP','PERUBAHAN_PERSEN']].astype(float)
        data.insert(0, 'BHN_PKKS', data['BHN_PKK'])

        #get backup for NO nonull
        NO_nonull=data[data['NO'].notnull()]
        SATUAN_nonull=NO_nonull[NO_nonull['SATUAN'].notnull()]
        SATUAN_nonull.drop(columns=['NO', 'BHN_PKK'], inplace=True)

        data=data[data['NO'].isnull()]
        data.drop(columns=['NO', 'BHN_PKK'], inplace=True)

        #append
        data = pd.concat([data, SATUAN_nonull], axis=0)

        data.columns=['JENIS','NAMA','SATUAN','HARGA_KMRN','HARGA_SKRG',"PERUB_RP","PERUB_PERSEN"]
        data['KAB'] = [payload['kabkota'][:-3].capitalize() if payload['kabkota'][-3:] == "kab" \
                       else payload['kabkota'][:4].capitalize() for i in range(len(data['JENIS']))]
        data['TANGGAL'] = [payload['tanggal'] for i in range(len(data['JENIS']))]

        #pasar
        market_index=np.where(np.array(market_data['m_id']) == payload['pasar'])[0][0]
        data['PASAR'] = [market_data['m_names'][market_index] for i in range(len(data['JENIS']))]
        return data


# Query by days
def query_days(days_input, start_date, end_date, nama_pasar, nama_kab):
    
    # days_input: "all"
    # start_date = min_date
    # end_date = max_date
    # nama_pasar = market_dict
    # nama_kab = region
    
    loop_date = _time_parse(days=days_input, min_date_input=start_date, max_date_input=end_date)
    for date in loop_date:
        market_data=nama_pasar
        for market_id, market_name in zip(market_data['m_id'], market_data['m_names']):
            payload={"tanggal": date,
                     "kabkota": nama_kab,
                     "pasar": market_id}
            element_day=_single_query(payload, market_data)
                
            if market_id == market_data['m_id'][0]:
                data = element_day
            else:
                data = pd.concat([data, element_day], axis=0)
            time.sleep(2)
        
        if date==loop_date[0]:
            data_append = data
        else:
            data_append = pd.concat([data_append, data], axis=0)

    return data_append


# Query by months

def query_months(days_input, start_date, end_date, nama_pasar, nama_kab):
    
    # days_input: "all"
    # start_date = min_date
    # end_date = max_date
    # nama_pasar = market_dict
    # nama_kab = region
    
    loop_months = _time_parse_month(start_date, end_date)
    for m in tqdm(loop_months, desc='Progress Bulan'):
        loop_date = _time_parse(days='all', min_date_input=m[0], max_date_input=m[-1])
        nama_bulan = m[0][0:8]
        for date in tqdm(loop_date, desc=f'Progress Hari {nama_bulan}'):
            market_data=nama_pasar
            for market_id, market_name in zip(market_data['m_id'], market_data['m_names']):
                payload={"tanggal": date,
                         "kabkota": nama_kab,
                         "pasar": market_id}
                element_day=_single_query(payload, market_data)
                    
                if market_id == market_data['m_id'][0]:
                    data = element_day
                else:
                    data = pd.concat([data, element_day], axis=0)
                time.sleep(2)
            
            if date==loop_date[0]:
                data_append = data
            else:
                data_append = pd.concat([data_append, data], axis=0)
            
            # progress_tanggal = np.round(index_d*100/len(loop_date), decimals=2)
            # print(f'progress loop hari {progress_tanggal} %')
        
        tanggal_awal = m[0].replace("-","")
        tanggal_akhir = m[-1].replace("-","")
        data_append.to_csv(f'{nama_kab}\{nama_kab}_{tanggal_awal}_{tanggal_akhir}.csv', index=False)
        
        # progress = np.round(index_m*100/len(loop_months), decimals=2)
        # print(f'progress loop bulan {progress} %')
        
        time.sleep(3)
