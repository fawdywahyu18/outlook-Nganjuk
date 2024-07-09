# outlook-Nganjuk
## Workflow Update Data Siskaperbapo Jawa Timur
Workflow ini dirancang untuk memperbarui data Siskaperbapo untuk kabupaten dan kota di Jawa Timur, dengan data terbaru dari situs web Siskaperbapo (https://siskaperbapo.jatimprov.go.id/).

**Langkah-langkah:**

**1. Unduh Skrip Update Data:**
+ Buka link GitHub berikut: https://github.com/fawdywahyu18/outlook-Nganjuk
+ Klik pada menu **<> Code** berwarna **hijau**
+ Klik **Download ZIP**
+ Ekstrak file terunduh di tempat yang diinginkan

**2. Persiapan**
+ Buka Anaconda
+ Buka CMD.exe Prompt
+ install virtual environment dengan command: **pip install virtualenv**
+ lakukan change directory dengan command : **cd <lokasi folder scrapping_siskaperbapo_windows>**
+ buat virtual environment dengan command: **virtualenv <env_name>**
+ aktifkan virtual environment dengan command: **<env_name>\Scripts\activate**

**3. Scrapping Data Siskaperbapo**
+ Buka Anaconda
+ Buka Spyder
+ Buka file run_ejperbo.py dengan cara:
	+ tekan **Ctrl+O**
	+ cari file **run_ejperbo.py** pada folder **scrapping_siskaperbapo_windows**
	+ sesuaikan tanggal data yang ingin di unduh pada bagian **min_date** dan **max_date**, sesuai rentang waktu 	yang diinginkan
	+ sesuaikan kota/kabupaten pada bagian **region**, sesuai dengan data kota/kabupaten yang ingin di unduh. 	Pasktikan penamaan kota/kabupaten sesuai dengan format berikut:
		**+ Kabupaten Nganjuk = nganjukkab**			**+ Kabupaten Blitar = blitarkab
		**+ Kabupaten Bojonegoro = bojonegorokab**		**+ Kabupaten Bondowoso = bondowosokab
		**+ Kabupaten Gresik = gresikkab**			**+ Kabupaten Jember = jemberkab
		**+ Kabupaten Jombang = jombangkab**			**+ Kota Kediri = kedirikota
		**+ Kabupaten Lamongan = lamongankab**			**+ Kabupaten Madiun = madiunkab
		**+ Kota Madiun = madiunkota**				**+ Kota Malang = malangkota
		**+ Kabupaten Mojokerto = mojokertokab**		**+ Kabupaten Ngawi = ngawikab
		**+ Kabupaten Pacitan = pacitankab**			**+ Kabupaten Pamekasan = pamekasankab
		**+ Kabupaten Pasuruan = pasuruankab**			**+ Kabupaten Ponorogo = ponorogokab
		**+ Kota Probolinggo = probolinggokota**		**+ Kabupaten Sidoarjo = sidoarjokab
		**+ Kabupaten Situbondo = situbondokab**		**+ Kabupaten Sumenep = sumenepkab
		**+ Kota Surabaya = surabayakota**
+ File akan otomatis tersimpan dalam bentuk CSV di folder **scrapping_siskaperbapo_windows** sesuai dengan kota/kabupaten yang diunduh.
