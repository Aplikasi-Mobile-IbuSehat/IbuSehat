<?php

namespace App\Services\Chat;

use App\Models\User;
use Illuminate\Support\Carbon;

/**
 * Menyusun konteks kesehatan pengguna untuk IbuSehat AI dari Data Kesehatan.
 *
 * PRIVASI: hanya data yang diperlukan untuk personalisasi yang dikirim ke
 * model — usia, tinggi, berat, target berat, IMT, dan lama pasca melahirkan.
 * Nama, email, foto, ID akun, dan tanggal melahirkan persisnya TIDAK dikirim
 * (tanggal diubah menjadi "sekitar N minggu/bulan lalu").
 */
class HealthContextBuilder
{
    /**
     * @return array<int, string>  baris-baris konteks; kosong jika belum ada data
     */
    public function lines(User $user, ?Carbon $now = null): array
    {
        $now ??= now();
        $lines = [];

        if ($user->age !== null) {
            $lines[] = "Usia: {$user->age} tahun";
        }

        if ($user->height !== null) {
            $lines[] = 'Tinggi badan: ' . $this->number($user->height) . ' cm';
        }

        if ($user->weight !== null) {
            $lines[] = 'Berat badan saat ini: ' . $this->number($user->weight) . ' kg';
        }

        if ($user->height !== null && $user->weight !== null && $user->height > 0) {
            $bmi = $user->weight / (($user->height / 100) ** 2);
            $lines[] = 'IMT: ' . number_format($bmi, 1, ',', '') . ' (' . $this->bmiCategory($bmi) . ')';
        }

        if ($user->target_weight !== null) {
            $line = 'Target berat badan: ' . $this->number($user->target_weight) . ' kg';

            if ($user->weight !== null) {
                $diff = round($user->target_weight - $user->weight, 1);
                $line .= match (true) {
                    $diff < 0  => ' (ingin turun ' . $this->number(abs($diff)) . ' kg)',
                    $diff > 0  => ' (ingin naik ' . $this->number($diff) . ' kg)',
                    default    => ' (ingin mempertahankan berat)',
                };
            }

            $lines[] = $line;
        }

        if ($user->delivery_date !== null) {
            $lines[] = $this->postpartumLine($user->delivery_date, $now);
        }

        return $lines;
    }

    private function postpartumLine(Carbon $deliveryDate, Carbon $now): string
    {
        $days = (int) floor($deliveryDate->copy()->startOfDay()->diffInDays($now->copy()->startOfDay(), false));

        if ($days < 0) {
            return 'Status: tanggal melahirkan yang diisi belum lewat (kemungkinan masih hamil atau baru akan melahirkan)';
        }

        $weeks  = intdiv($days, 7);
        $months = (int) floor($days / 30.44);

        $duration = match (true) {
            $days < 14   => "sekitar {$days} hari lalu",
            $weeks < 13  => "sekitar {$weeks} minggu lalu",
            $months < 24 => "sekitar {$months} bulan lalu",
            default      => 'lebih dari 2 tahun lalu',
        };

        $phase = match (true) {
            $weeks < 6   => 'masih masa nifas (6 minggu pertama)',
            $months < 6  => 'sudah melewati masa nifas 6 minggu, masih dalam 6 bulan pertama',
            $months < 12 => 'tahun pertama pasca melahirkan',
            default      => 'lebih dari setahun pasca melahirkan',
        };

        return "Melahirkan: {$duration} — {$phase}";
    }

    private function bmiCategory(float $bmi): string
    {
        return match (true) {
            $bmi < 18.5 => 'berat badan kurang',
            $bmi < 25   => 'normal',
            $bmi < 30   => 'berat badan berlebih',
            default     => 'obesitas',
        };
    }

    private function number(float|int $value): string
    {
        return rtrim(rtrim(number_format((float) $value, 1, ',', ''), '0'), ',');
    }
}
