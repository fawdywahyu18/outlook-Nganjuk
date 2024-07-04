# outlook-Nganjuk
## Workflow Proyeksi PDRB Total, Industri Pengolahan, dan Sektor Pertanian, Kehutanan, dan Perikanan Kabupaten Nganjuk

1. Update Data PDRB
+ Sumber Data: Akses situs web https://simreg.bappenas.go.id/home/video untuk memperbarui data PDRB.
+ Prosedur Update: Ikuti prosedur update data dan gunakan kode yang disediakan dalam folder `update_pdrb_jatim`.
+ Penyimpanan Data: Simpan data hasil update ke folder `outlook-Nganjuk`.

2. Persiapan Script R
+ Nama File: Ubah nama file data di dalam script run_pdrb_nganjuk.R baris ke 16 agar sesuai dengan nama file terbaru hasil update di langkah 1.
+ Parameter 2L dan 5L: Ubah nilai parameter 2L dan 5L di dalam script run_pdrb_nganjuk.R sesuai kebutuhan. Parameter ini merujuk pada bilangan bulat positif terkait number of horizon (nhor).
++ Perhatikan bahwa:
+++ evaluasi_pvar dan evaluasi_bgvar hanya menerima input nhor berupa bilangan bulat positif minimal 1 dan maksimal 3.
+++ out_forecast_pvar dan out_forecast_bgvar hanya menerima input nhor berupa bilangan bulat positif minimal 1 dan maksimal 7.
