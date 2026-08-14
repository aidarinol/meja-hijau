---
title: "Judul artikel antrean"
description: "Deskripsi 1-2 kalimat (dipakai meta & ringkasan)."
pubDate: 2099-01-01
author: larasati-dewi
kicker: ""
tags: []
draft: true
sources: []
---

TEMPLATE — jangan diterbitkan. Untuk mengantre artikel:
1. Salin file ini menjadi `_NNN-judul-slug.md` (mis. `_002-....md`). Nomor menentukan URUTAN rilis (kecil dulu).
2. Isi konten & frontmatter, biarkan `draft: true` dan awalan `_`.
3. Commit + push. Setiap 3 hari, cron merilis satu file bernomor terkecil: awalan `_` dilepas, `draft:false`, tanggal distempel hari rilis.
File berawalan `_` diabaikan Astro DAN dilewati skrip rilis, jadi TEMPLATE ini aman.
