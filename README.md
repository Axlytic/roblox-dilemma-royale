# Dilemma Royale: Perks & Status 👑

> Sebuah game psikologi sosial multiplayer di platform **Roblox**, dibangun dengan pendekatan **Vibe Coding** dan arsitektur sistem berbasis **Luau Modular**.

---

## 🎮 4 Pilar Aspek Gameplay (Full Production Architecture)

### 1. Kedalaman Arena & Dynamic Modifiers (Aspek 1)
* **Underdog / Minority Rules**: Menggunakan sensor hitung kepala (*headcount*). Kubu minoritas selamat, mayoritas runtuh!
* **Dynamic Modifiers**:
  * *Lantai Es Licin*: Gesekan 0.01, sulit mengerem.
  * *Gravitasi Bulan*: Lompatan melayang tinggi.
  * *Lantai Mengecil*: Pelat menyusut saat countdown, memaksa pemain berdesakan.
  * *Standar Arena*: Putaran normal.
* **The Neutral Beam**: Balok emas penyeimbang sempit di tengah. Pemain yang bertahan di atasnya saat waktu habis dinyatakan `NEUTRAL SURVIVOR` (+15 Koin).
* **The Greed Orb**: Bola energi koin spawn di perbatasan tengah saat voting, memicu uji nyali berebut koin.
* **3 Kategori Layar Raksasa**: *Dilema Sosial Populer*, *Tactical Survival*, dan *Greed Dilemma*.

---

### 2. Sistem Atribut Stat RPG (Aspek 2)
Pemain dapat meningkatkan level atribut menggunakan Koin melalui menu **⚡ ATRIBUT**:
* **Agility (Lv 1 - 10)**: Meningkatkan WalkSpeed dan JumpPower (+ Multi-Jump height).
* **Weight / Anti-Push (Lv 1 - 10)**: Memperberat massa fisik karakter (`Density`). Menolak dorongan skill lawan hingga 55% dan lebih stabil di lantai es!
* **Luck (Lv 1 - 10)**: Peluang mendapatkan bonus Koin 1.5x saat menang dan ekstra koin saat mengambil Greed Orb.
* **DataStore Persistence**: Seluruh stat tersimpan permanen di cloud database.

---

### 3. Variasi Skill Taktikal & HUD Cooldown (Aspek 3)
HUD 3 slot di bawah layar yang responsif untuk **Keyboard PC (Q, E, R)** maupun **Layar Sentuh Mobile**:
* **[Q] Force Push**: Mendorong pemain lain dalam radius 18 studs. Efektivitas dorongan ditangkis oleh stat *Weight* target. Cooldown: 10s.
* **[E] Speed Dash**: Melesat secepat kilat (+42 WalkSpeed) selama 2.5 detik dengan efek visual trail neon. Cooldown: 8s.
* **[R] Gravity Feather**: Mengurangi efek gravitasi 55% selama 4 detik, memungkinkan melayang saat lantai di bawah runtuh! Cooldown: 12s.
* **Anti-Exploit Server Validation**: Seluruh cooldown dan impulse fisika diverifikasi ketat di server (`SkillServerHandler`).

---

### 4. Tata Letak Colosseum Stadium & Relokasi VIP (Aspek 4)
* **Colosseum Circular Viewing Deck (Y = 60)**:
  * Lobi penonton bertingkat melingkar mengelilingi panggung arena utama.
  * Dilengkapi **Pagar Kaca Transparan Spectator** sehingga pemain yang menunggu atau gugur bisa menonton pertarungan di bawah dari dekat (*Close Spectator UX*).
* **The Imperial VIP Box**:
  * Dipindahkan ke balkon kehormatan di tengah tribun Colosseum (bukan lagi terpencil di awan).
  * Dilengkapi **Kursi Tahta Emas Kaisar (*Golden Throne*)**, karpet merah, dan pilar marmer bermahkota emas.
  * Terlihat jelas dan prestisius bagi seluruh pemain di lobi!
  * Terkoneksi dengan gerbang sensor Game Pass VIP (ID: `2064678688`) dan bypass otomatis untuk Developer (`Axlytic0`).

---

## 📁 Struktur Direktori Repositori
```
roblox-dilemma-royale/
├── src/
│   ├── server/
│   │   ├── DilemmaServer.luau       # Otak putaran game, sensor headcount, modifier, & Greed Orb
│   │   ├── StatsServerHandler.luau  # Server-side RPG Stats (Agility, Weight/Anti-push, Luck)
│   │   ├── SkillServerHandler.luau  # Validasi server cooldown skill (Force Push, Dash, Float)
│   │   ├── ColosseumBuilder.luau    # Arsitektur Colosseum Stadium & Imperial VIP Box
│   │   ├── ShopServerHandler.luau   # Logika transaksi perk & kosmetik
│   │   └── VIPPassHandler.luau      # Verifikasi gerbang sensor Imperial VIP Game Pass
│   └── client/
│       ├── DoubleJumpClient.luau    # Multi-jump dengan scaling Agility stat
│       ├── SkillHUDController.luau  # HUD Bar Skill (Q, E, R) dengan cooldown countdown
│       ├── StatsMenuController.luau # GUI Menu Upgrade Stat RPG Glassmorphism
│       └── ShopController.luau      # GUI Toko Perk
├── GEMINI.md                        # Aturan pengingat GitHub streak harian persisten
└── README.md                        # Dokumentasi arsitektur game
```

---
*Dibuat oleh Axlytic (Ehan) - 2026*
