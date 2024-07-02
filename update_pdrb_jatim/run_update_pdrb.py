"""
Run Update data PDRB Seluruh Jatim
@author: fawdywahyu
"""

from update_pdrb_jatim import cleaning_data, creating_pdrb_df


kode_jatim = ['3501', '3502', '3503', '3504', '3505', '3506', '3507',
              '3508', '3509', '3510', '3511', '3512', '3513', '3514',
              '3515', '3516', '3517', '3518', '3519', '3520', '3521',
              '3522', '3523', '3524', '3525', '3526', '3527', '3528',
              '3529', '3571', '3572', '3573', '3574', '3575', '3576',
              '3577', '3578', '3579']

daftar_tahun = ['2010', '2011', '2012', '2013', '2014', '2015', '2016', 
                '2017', '2018', '2019', '2020', '2021', '2022']

tahun_awal = daftar_tahun[0]
tahun_akhir = daftar_tahun[-1]
pdrb_jatim = creating_pdrb_df(daftar_tahun, kode_jatim)
pdrb_jatim.to_excel(f'PDRB Jawa Timur Lapangan Usaha {tahun_awal} {tahun_akhir}.xlsx', index=False)

