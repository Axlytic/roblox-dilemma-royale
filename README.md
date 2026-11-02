# Dilemma Royale: Perks & Status 👑

> Sebuah game psikologi sosial multiplayer di platform **Roblox**, dibangun dengan pendekatan **Vibe Coding** dan arsitektur sistem berbasis **Luau**.

---

## 🎮 Konsep Utama Permainan
* **Social Dilemma Arena**: Pemain dihadapkan pada dua kubu pilihan (*Merah vs Biru*) dengan pertanyaan dilema sosial di layar LED raksasa.
* **Underdog / Minority Rules**: Menggunakan sensor hitung kepala (*headcount sensor*). Kubu dengan jumlah pemain paling sedikit adalah yang selamat, sedangkan kubu mayoritas akan runtuh ke jurang!
* **Dynamic Round Modifiers**:
  * *Lantai Es Licin* (Friction 0.01)
  * *Gravitasi Bulan* (Low Gravity 50)
  * *Lantai Mengecil* (Shrinking Plates)
  * *Ronde Normal*

---

## ⚡ Sistem Skill & Atribut (Perks)
* **Double Jump (Agility)**: Kemampuan melompat 2x di udara untuk menyelamatkan diri di detik terakhir.
* **Force Push**: Alat pendorong lawan.
* **Speed Dash**: Peningkatan kelincahan dan kecepatan lari.
* **Gravity Feather**: Melayang lebih lama di udara.

---

## 👑 Status Sosial & Fasilitas VIP
* **Overhead Titles**: `[ ROOKIE ]`, `[ SURVIVOR ]`, dan `[ SULTAN DILEMA ★ ]` dengan partikel emas.
* **VIP Sky Lounge (Y = 90)**: Ruangan observasi kaca melayang dengan **Kursi Tahta Emas**.
* **Integrasi Game Pass**: Terhubung dengan `MarketplaceService` (Game Pass ID: `2064678688`).

---

## 💾 Arsitektur & Keamanan Data
* **DataStoreService**: Menyimpan progres `Wins` dan `Coins` pemain secara persisten dengan sistem perlindungan *Safe Pcall*, *Auto-Save* setiap 60 detik, dan *BindToClose*.
* **UI/UX Toast System**: Notifikasi visual real-time saat data berhasil dimuat atau disimpan.

---

## 📁 Struktur Direktori
```
roblox-dilemma-royale/
├── src/
│   ├── server/
│   │   ├── DilemmaServer.luau       # Otak putaran game, sensor headcount, & modifier
│   │   ├── ShopServerHandler.luau   # Logika transaksi toko perk & kosmetik
│   │   └── VIPPassHandler.luau      # Sensor gerbang karpet merah & Game Pass VIP
│   └── client/
│       ├── DoubleJumpClient.luau    # Logika deteksi spasi 2x di keyboard
│       └── ShopController.luau      # UI interaksi modal toko Glassmorphism
└── README.md
```

---
*Dibuat oleh Axlytic (Ehan) - 2026*
