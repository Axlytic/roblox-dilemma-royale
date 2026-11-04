# Aturan Khusus: Pengingat Harian Kontribusi GitHub (Persistent Daily Streak Tracker)

> [!IMPORTANT]
> **ATURAN PENGINGAT PERSISTEN HINGGA DI-PUSH (PERSISTENT UNTIL PUSHED)**:
> 
> 1. **Pemicu Harian & Percakapan**:
>    * Setiap hari baru atau setiap kali pengguna memulai percakapan baru, asisten AI **WAJIB** memeriksa status kontribusi GitHub untuk hari tersebut.
> 
> 2. **Siklus Pengingat Tanpa Putus (Persistent Reminder)**:
>    * Jika pada hari tersebut **BELUM** ada commit & push ke GitHub, asisten AI **WAJIB terus mengingatkan** di awal atau akhir respons.
>    * Pengingat ini **TIDAK BOLEH BERHENTI** hanya di pesan pertama; pengingat harus **tetap konsisten muncul di percakapan yang sama maupun di percakapan baru berikutnya** sampai commit & push untuk hari tersebut benar-benar berhasil dieksekusi.
> 
> 3. **Kondisi Selesai (Streak Hari Ini Aman)**:
>    * Begitu proses `git commit` dan `git push` untuk hari tersebut berhasil dijalankan dan tercatat di GitHub (streak hijau hari itu menyala), asisten AI memberikan konfirmasi hangat bahwa kontribusi hari ini sudah sukses.
>    * Setelah itu, asisten AI tidak perlu terus mengingatkan lagi di sisa hari tersebut, kecuali ada perubahan besar baru yang siap di-push.
> 
> 4. **Format Pengingat**:
>    * Selipkan pengingat hangat dan memotivasi (misalnya: menanyakan progres apa yang siap di-commit, atau menawarkan bantuan langsung untuk mengeksekusi `git add`, `commit`, dan `push`).



---

# Aturan Khusus: Pengingat Refresh Percakapan Baru Saat Konteks Penuh (Context Refresh & Handover Rule)

> [!IMPORTANT]
> **PENGINGAT MEMBUAT PERCAKAPAN BARU SAAT CHAT PANJANG/PENUH**:
> 
> 1. **Pemicu**:
>    * Ketika percakapan sudah berjalan sangat panjang, mengalami auto-compaction, atau konteks mulai padat sehingga ada risiko kehilangan detail teknis minor.
> 
> 2. **Kewajiban Asisten AI**:
>    * Di akhir respons, asisten AI **WAJIB** menyisipkan bagian pengingat ramah (*Context Refresh Callout*) yang menyarankan pengguna untuk membuka percakapan baru.
>    * Asisten harus menyertakan:
>      - **ID Percakapan Saat Ini**: Tautan markdown `[Lanjutkan dari Percakapan Sebelumnya](conversation://<conversation-id>)` dan teks Conversation ID.
>      - **Poin Status Terakhir (Status Snapshot)**: Rangkuman singkat tentang apa yang baru saja diselesaikan dan apa langkah berikutnya yang siap dieksekusi di percakapan baru.
> 
> 3. **Tujuan**:
>    * Menjaga performa AI tetap cepat, responsif, dan memastikan transisi ke percakapan baru berjalan mulus tanpa kehilangan konteks proyek sedikit pun.
