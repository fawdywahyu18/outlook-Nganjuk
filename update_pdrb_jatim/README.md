# outlook-Nganjuk
## Workflow Update Data PDRB Seluruh Jawa Timur
Workflow ini dirancang untuk memperbarui data PDRB (Produk Domestik Regional Bruto) seluruh Jawa Timur dengan data terbaru dari situs web Badan Perencanaan Pembangunan Nasional (Bappenas).

**Langkah-langkah:**

**1. Unduh Data Terbaru:**
+ Buka situs web Bappenas: https://simreg.bappenas.go.id/home/datadasar
+ Unduh file Excel terbaru yang berisi data PDRB ADHK 2010 seluruh lapangan usaha untuk Jawa Timur.
+ Simpan file data terbaru ke dalam folder `Data`.
+ Ubah nama file sesuai dengan nama file yang telah ada. Misalkan, data terbaru tahun 2024, nama file haruslah `PDRB Lapangan Usaha Kab Kota Dalam Milyar Seluruh Indonesia ADHK tahun 2024.xlsx`.

**2. Perbarui Script `run_pdrb_jatim.py`:**
+ Buka script `run_pdrb_jatim.py` dengan menggunakan Jupyter Notebook.
+ Ubah list `daftar_tahun` dengan menambahkan tahun terbaru (misalkan `2024`) ke dalam list. List daftar_tahun harus memiliki elemen `2024` di sebelah `2023`.
+ Simpan perubahan script.

**3. Jalankan Script `run_pdrb_jatim.py`:**
Jalankan script `run_pdrb_jatim.py`.

**Hasil:**
+ File Excel baru dengan nama `PDRB Jawa Timur Lapangan Usaha 2010 2024.xlsx` akan dibuat di dalam folder `update_pdrb_jatim`. File ini berisi data PDRB Jawa Timur yang diperbarui untuk tahun 2024.

**Catatan:**
+ Pastikan Anda menggunakan data terbaru dari situs web Bappenas.
+ Ubah nama file data terbaru dan list `daftar_tahun` sesuai dengan tahun yang diperbarui.
+ Jalankan script `run_pdrb_jatim.py` setelah memperbarui data dan script.

**Manfaat:**
+ Workflow ini membantu Anda memperbarui data PDRB Jawa Timur dengan mudah dan efisien.
+ Data PDRB yang terbaru penting untuk analisis dan perencanaan ekonomi.
