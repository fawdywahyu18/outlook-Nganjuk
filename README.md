# outlook-Nganjuk
## Workflow Proyeksi PDRB Total, Industri Pengolahan, dan Sektor Pertanian, Kehutanan, dan Perikanan Kabupaten Nganjuk

**1. Update Data PDRB**
+ Sumber Data: Akses situs web https://simreg.bappenas.go.id/home/datadasar untuk memperbarui data PDRB.
+ Prosedur Update: Ikuti prosedur update data dan gunakan kode yang disediakan dalam folder `update_pdrb_jatim`.
+ Penyimpanan Data: Simpan data hasil update ke folder `outlook-Nganjuk`.

**2. Persiapan Script R**
+ Nama File: Ubah nama file data di dalam script `run_pdrb_nganjuk.R` baris ke 16 agar sesuai dengan nama file terbaru hasil update di langkah 1.
+ Parameter `2L` dan `5L`: Ubah nilai parameter `2L` dan `5L` di dalam script `run_pdrb_nganjuk.R` sesuai kebutuhan. Parameter ini merujuk pada bilangan bulat positif terkait number of horizon (nhor).
  + Perhatikan bahwa:
    + `evaluasi_pvar` dan `evaluasi_bgvar` hanya menerima input nhor berupa bilangan bulat positif minimal `1` dan maksimal `3`.
    + `out_forecast_pvar` dan `out_forecast_bgvar` hanya menerima input nhor berupa bilangan bulat positif minimal `1` dan maksimal `7`.

**3. Eksekusi Script R**
+ Jalankan script `run_pdrb_nganjuk.R` untuk melakukan proyeksi dan evaluasi.

**4. Hasil Evaluasi dan Proyeksi**
+ Evaluasi: Hasil evaluasi proyeksi disimpan dalam file Excel di folder `Export`.
+ Out-of-Sample Forecast: Hasil out-of-sample forecast disimpan dalam file Excel di folder `Export`.

**Catatan:**
+ Seluruh hasil evaluasi dan out-of-sample forecast bernilai Milyar Rupiah.
+ Dokumentasi hasil dan evaluasi proyeksi berada di file `Dokumentasi Hasil dan Evaluasi Proyeksi Perekonomian Kabupaten Nganjuk.pdf`.
+ Dokumentasi outlook perekonomian Kabupaten Nganjuk 2024-2027 berada di file `Dokumentasi Outlook Perekonomian Nganjuk 2024 2027.pdf`.
+ Dokumentasi data dan metodologi proyeksi perekonomian dan analisis harga Kabupaten Nganjuk berada di file `Dokumentasi Data dan Metodologi Proyeksi Perekonomian dan Analisis Harga Nganjuk.pdf`

**Informasi Tambahan:**
+ Workflow ini dirancang untuk memproyeksikan PDRB total, industri pengolahan, dan sektor pertanian Kabupaten Nganjuk.
+ Script R yang digunakan dalam workflow ini dapat dimodifikasi sesuai dengan kebutuhan.
+ Penting untuk memperbarui data PDRB secara berkala untuk mendapatkan proyeksi yang akurat.

**Spesifikasi Komputer:**
------------------
System Information
------------------
             Machine name: DESKTOP-HH446AV
               Machine Id: {DCF02BE2-76CE-4FA4-9F88-8AB26AADDF76}
         Operating System: Windows 11 Home Single Language 64-bit (10.0, Build 22631) (22621.ni_release.220506-1250)
                 Language: English (Regional Setting: English)
      System Manufacturer: Dell Inc.
             System Model: Vostro 3681
                     BIOS: 2.5.1 (type: UEFI)
                Processor: Intel(R) Core(TM) i7-10700 CPU @ 2.90GHz (16 CPUs), ~2.9GHz
                   Memory: 8192MB RAM
      Available OS Memory: 7940MB RAM
                Page File: 9562MB used, 11041MB available
              Windows Dir: C:\WINDOWS
          DirectX Version: DirectX 12
      DX Setup Parameters: Not found
         User DPI Setting: 96 DPI (100 percent)
       System DPI Setting: 96 DPI (100 percent)
          DWM DPI Scaling: Disabled
                 Miracast: Available, with HDCP
Microsoft Graphics Hybrid: Not Supported
 DirectX Database Version: 1.6.0
           DxDiag Version: 10.00.22621.3527 64bit Unicode

