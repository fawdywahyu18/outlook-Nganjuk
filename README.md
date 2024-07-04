# outlook-Nganjuk
## Workflow Proyeksi PDRB Total, Industri Pengolahan, dan Sektor Pertanian, Kehutanan, dan Perikanan Kabupaten Nganjuk

_1. Update Data PDRB_
+ Sumber Data: Akses situs web https://simreg.bappenas.go.id/home/video untuk memperbarui data PDRB.
+ Prosedur Update: Ikuti prosedur update data dan gunakan kode yang disediakan dalam folder `update_pdrb_jatim`.
+ Penyimpanan Data: Simpan data hasil update ke folder `outlook-Nganjuk`.

_2. Persiapan Script R_
+ Nama File: Ubah nama file data di dalam script `run_pdrb_nganjuk.R` baris ke 16 agar sesuai dengan nama file terbaru hasil update di langkah 1.
+ Parameter `2L` dan `5L`: Ubah nilai parameter `2L` dan `5L` di dalam script `run_pdrb_nganjuk.R` sesuai kebutuhan. Parameter ini merujuk pada bilangan bulat positif terkait number of horizon (nhor).
  + Perhatikan bahwa:
    + `evaluasi_pvar` dan `evaluasi_bgvar` hanya menerima input nhor berupa bilangan bulat positif minimal `1` dan maksimal `3`.
    + `out_forecast_pvar` dan `out_forecast_bgvar` hanya menerima input nhor berupa bilangan bulat positif minimal `1` dan maksimal `7`.

_3. Eksekusi Script R_
+ Jalankan script `run_pdrb_nganjuk.R` untuk melakukan proyeksi dan evaluasi.

_4. Hasil Proyeksi_
+ Evaluasi: Hasil evaluasi proyeksi disimpan dalam file Excel di folder `Export`.
+ Out-of-Sample Forecast: Hasil out-of-sample forecast disimpan dalam file Excel di folder `Export`.

_Catatan:_
+ Seluruh hasil evaluasi dan out-of-sample forecast bernilai Milyar Rupiah.

_Informasi Tambahan:_
+ Workflow ini dirancang untuk memproyeksikan PDRB total, industri pengolahan, dan sektor pertanian Kabupaten Nganjuk.
+ Script R yang digunakan dalam workflow ini dapat dimodifikasi sesuai dengan kebutuhan.
+ Penting untuk memperbarui data PDRB secara berkala untuk mendapatkan proyeksi yang akurat.
