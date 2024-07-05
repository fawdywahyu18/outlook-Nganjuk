"""
running scrapping siskaperbapo

@author: fawdywahyu
"""

from ejperbo_modules import _market_parse, query_months

import pandas as pd
import requests
import warnings
warnings.filterwarnings("ignore")

pd.options.mode.chained_assignment = None  # default='warn'

URL="https://siskaperbapo.jatimprov.go.id/harga/tabel"
PASAR_ENDPOINT="https://siskaperbapo.jatimprov.go.id/harga/pasar.json/"
ENDPOINT="https://siskaperbapo.jatimprov.go.id/harga/tabel.nodesign/"
data = pd.DataFrame(dict(JENIS=[],NAMA=[],SATUAN=[],HARGA_KMRN=[],HARGA_SKRG=[],
                         PERUB_RP=[], PERUB_PERSEN=[], KAB=[], TANGGAL=[], PASAR=[]))
market_data=[]

min_date = '2024-06-01'
max_date = '2024-06-30'
region = 'nganjukkab'

with requests.session() as rs:
    rs.get(URL)
    rp=rs.get(PASAR_ENDPOINT+region)
market_names=[rp.json()[i]['psr_nama'] for i in range(len(rp.json()))]
market_id=[rp.json()[i]['psr_id'] for i in range(len(rp.json()))]

market_dict = _market_parse(URL, PASAR_ENDPOINT, region, min_date, max_date)

query_months(days_input='all', start_date=min_date, 
             end_date=max_date, nama_pasar=market_dict, nama_kab=region)

