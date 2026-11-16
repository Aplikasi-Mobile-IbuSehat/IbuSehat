<?php

namespace App\Services\Chat;

/**
 * Deteksi tanda bahaya pada pesan pengguna — dilakukan di BACKEND dengan
 * aturan tetap, tidak bergantung pada AI.
 *
 * Jika cocok, backend selalu menampilkan pesan darurat baku (lihat message())
 * di awal balasan, apa pun jawaban model — bahkan saat Gemini gagal/mati.
 *
 * Deteksi sengaja condong ke "lebih baik salah memperingatkan daripada
 * terlewat": pola krisis kejiwaan tidak pernah dibatalkan oleh kata negasi.
 */
class EmergencyDetector
{
    public const MENTAL_CRISIS = 'krisis_kejiwaan';
    public const BLEEDING      = 'perdarahan';
    public const SEIZURE_BP    = 'kejang_tekanan_darah';
    public const BREATH_CHEST  = 'napas_dada';
    public const FAINTING      = 'pingsan';
    public const INFECTION     = 'infeksi';
    public const BLOOD_CLOT    = 'bekuan_darah';
    public const BABY          = 'bayi';

    /**
     * Urutan = prioritas. Pola dicocokkan pada teks huruf kecil.
     *
     * @var array<string, array<int, string>>
     */
    private const PATTERNS = [
        self::MENTAL_CRISIS => [
            '/bunuh\s+diri/u',
            '/(mengakhiri|akhiri)\s+hidup/u',
            '/(tidak|nggak|gak|ga|enggak|tdk)\s+(ingin|mau|pengen|pingin|sanggup)\s+hidup/u',
            '/lebih\s+baik\s+(aku|saya|gue|gw)?\s*mati/u',
            '/(ingin|mau|pengen|pingin|kepikiran|terpikir|berpikir)\s+(untuk\s+)?mati/u',
            '/(menyakiti|melukai|mencelakai|membunuh)\s+(diri|bayi|anak)/u',
            '/(ingin|mau|pengen|pingin|kepikiran|terpikir)\s+(untuk\s+)?(menyakiti|melukai|mencelakai|membunuh)/u',
        ],
        // Bayi didahulukan dari kategori ibu, supaya "bayi saya kejang" tidak
        // dijawab dengan pesan preeklamsia untuk ibu.
        self::BABY => [
            '/bayi[^.!?]{0,30}(tidak\s+ber(napas|nafas)|sulit\s+ber(napas|nafas)|sesak|kebiruan|membiru|kejang|tidak\s+sadar|lemas\s+sekali|sangat\s+lemas)/u',
            '/bayi[^.!?]{0,30}(tidak|nggak|gak)\s+mau\s+(menyusu|minum)\s+(sama\s+sekali|seharian)/u',
        ],
        self::BLEEDING => [
            '/(perdarahan|pendarahan)\s+(yang\s+)?(sangat\s+)?(hebat|banyak|deras|parah|berat)/u',
            '/(perdarahan|pendarahan|darah)\s+(yang\s+)?(tidak|nggak|gak|ga|tak)\s+(mau\s+)?(berhenti|henti)/u',
            '/darah\s+(nifas\s+)?(yang\s+)?(keluar\s+)?(sangat\s+|banyak\s+)?(banyak|deras|mengucur|mengalir\s+deras)/u',
            '/ganti\s+pembalut\s+(tiap|setiap|per)\s+(1\s+|satu\s+|se)?jam/u',
            '/pembalut\s+penuh\s+(dalam|kurang\s+dari)\s+(1\s+|satu\s+|se)?jam/u',
            '/gumpalan\s+darah\s+(yang\s+)?(sangat\s+)?(besar|sebesar)/u',
        ],
        self::SEIZURE_BP => [
            '/kejang/u',
            '/sakit\s+kepala\s+(yang\s+)?(sangat\s+)?(hebat|berat|parah)/u',
            '/(pandangan|penglihatan|mata)\s+(tiba-tiba\s+|mendadak\s+)?(kabur|buram|gelap|berkunang)/u',
        ],
        self::BREATH_CHEST => [
            '/sesak\s+(napas|nafas)/u',
            '/(sulit|susah|sukar)\s+(ber)?(napas|nafas)/u',
            '/nyeri\s+dada/u',
            '/dada\s+(terasa\s+)?(sakit|nyeri|sesak|tertekan)/u',
            '/batuk\s+(ber)?darah/u',
        ],
        self::FAINTING => [
            '/pingsan/u',
            '/(tidak|tak)\s+sadarkan\s+diri/u',
            '/hilang\s+kesadaran/u',
        ],
        self::INFECTION => [
            '/demam\s+(yang\s+)?(sangat\s+)?(tinggi|menggigil)/u',
            '/demam\s+(sampai\s+|hingga\s+|di\s+atas\s+|lebih\s+dari\s+)?(38[,.][5-9]|39|4[0-2])/u',
            '/(luka|jahitan|bekas)\s+(operasi|jahitan|sesar|caesar|sc|episiotomi)?[^.!?]{0,30}(bernanah|nanah|terbuka|bau\s+busuk|berbau)/u',
            '/(cairan|keputihan|lokia|darah\s+nifas)[^.!?]{0,25}(berbau\s+busuk|bau\s+busuk|bau\s+menyengat)/u',
        ],
        self::BLOOD_CLOT => [
            '/betis[^.!?]{0,25}(bengkak|nyeri|sakit|merah|panas)/u',
            '/kaki\s+(sebelah\s+|kiri\s+|kanan\s+)?bengkak[^.!?]{0,25}(nyeri|sakit|merah|panas)/u',
        ],
    ];

    /** Kata negasi yang, bila tepat mendahului pola, membatalkan kecocokan. */
    private const NEGATION_BEFORE = '/\b(tidak|tdk|nggak|gak|ga|enggak|tanpa|bukan|belum)\s+(ada\s+|pernah\s+|sampai\s+|mengalami\s+|merasa\s+|merasakan\s+|ada\s+tanda\s+)?$/u';

    /**
     * @return ?string  kategori darurat, atau null jika tidak terdeteksi
     */
    public function detect(string $text): ?string
    {
        $normalized = mb_strtolower(preg_replace('/\s+/u', ' ', trim($text)) ?? '');

        if ($normalized === '') {
            return null;
        }

        foreach (self::PATTERNS as $category => $patterns) {
            foreach ($patterns as $pattern) {
                if (!preg_match($pattern, $normalized, $match, PREG_OFFSET_CAPTURE)) {
                    continue;
                }

                // Krisis kejiwaan: tidak pernah dibatalkan oleh negasi.
                if ($category !== self::MENTAL_CRISIS && $this->isNegated($normalized, $match[0][1])) {
                    continue;
                }

                return $category;
            }
        }

        return null;
    }

    /**
     * Pesan darurat baku (Markdown). Selalu ditampilkan backend di awal balasan.
     */
    public function message(string $category): string
    {
        $ambulance = (string) config('services.emergency.ambulance', '119');
        $general   = (string) config('services.emergency.general', '112');

        if ($category === self::MENTAL_CRISIS) {
            return implode("\n", [
                '**Terima kasih sudah mau bercerita. Kamu tidak sendirian, dan perasaan seberat ini bisa ditangani.**',
                '',
                'Kalau saat ini kamu merasa bisa menyakiti dirimu atau bayimu:',
                '- **Jangan sendirian.** Minta pasangan, keluarga, atau tetangga menemanimu sekarang.',
                '- Letakkan bayi di tempat yang aman (misalnya boks bayi), lalu menjauh sejenak untuk menenangkan diri.',
                "- Hubungi **{$ambulance}** atau **{$general}**, atau segera ke IGD rumah sakit terdekat.",
                '',
                'Ceritakan juga hal ini ke dokter, bidan, atau psikolog. Depresi pasca melahirkan adalah kondisi medis, bukan salahmu, dan ada pengobatannya.',
            ]);
        }

        [$headline, $steps] = match ($category) {
            self::BLEEDING => [
                'Perdarahan banyak setelah melahirkan bisa berbahaya dan perlu ditangani segera.',
                ['Berbaring dan jangan beraktivitas berat sambil menunggu pertolongan.'],
            ],
            self::SEIZURE_BP => [
                'Kejang, sakit kepala hebat, atau pandangan kabur setelah melahirkan bisa menjadi tanda preeklamsia/eklamsia.',
                ['Jangan menyetir sendiri. Minta orang lain mengantar.'],
            ],
            self::BREATH_CHEST => [
                'Sesak napas atau nyeri dada setelah melahirkan bisa menandakan masalah jantung atau paru-paru yang serius.',
                ['Duduk tegak, longgarkan pakaian, dan jangan dipaksa berjalan jauh.'],
            ],
            self::FAINTING => [
                'Pingsan atau hilang kesadaran setelah melahirkan perlu diperiksa segera.',
                ['Berbaring dengan kaki sedikit ditinggikan, dan jangan ditinggal sendirian.'],
            ],
            self::INFECTION => [
                'Demam tinggi, luka bernanah, atau cairan berbau busuk setelah melahirkan bisa menjadi tanda infeksi.',
                ['Jangan menunda sampai besok, dan jangan minum antibiotik tanpa resep.'],
            ],
            self::BLOOD_CLOT => [
                'Betis atau kaki yang bengkak, nyeri, merah, atau panas bisa menjadi tanda bekuan darah.',
                ['Jangan dipijat atau diurut.'],
            ],
            self::BABY => [
                'Tanda ini pada bayi perlu pertolongan segera.',
                ['Jaga bayi tetap hangat dan terus awasi napasnya selama perjalanan.'],
            ],
            default => [
                'Keluhan ini perlu diperiksa tenaga kesehatan segera.',
                [],
            ],
        };

        $lines = [
            '**⚠️ Ini bisa jadi kondisi darurat.**',
            $headline,
            '',
            '**Lakukan sekarang:**',
            "- Segera ke IGD rumah sakit atau fasilitas kesehatan terdekat, atau hubungi **{$ambulance}** (ambulans) / **{$general}**.",
        ];

        foreach ($steps as $step) {
            $lines[] = "- {$step}";
        }

        $lines[] = '- Minta pasangan atau keluarga menemanimu.';
        $lines[] = '';
        $lines[] = 'IbuSehat AI tidak bisa memeriksa atau menggantikan tenaga kesehatan.';

        return implode("\n", $lines);
    }

    private function isNegated(string $text, int $byteOffset): bool
    {
        $start  = max(0, $byteOffset - 40);
        $before = mb_strcut($text, $start, $byteOffset - $start);

        return (bool) preg_match(self::NEGATION_BEFORE, $before);
    }
}
