<?php

namespace Database\Seeders;

use App\Models\Food;
use App\Models\Supplement;
use Illuminate\Database\Seeder;

class FoodAndSupplementSeeder extends Seeder
{
    public function run(): void
    {
        // ─── FOODS ───────────────────────────────────────────────────────────
        $foods = [
            // Nasi & Karbohidrat
            ['name' => 'Nasi Putih', 'category' => 'Karbohidrat', 'calories' => 204, 'protein' => 4.2, 'carbohydrate' => 44.5, 'fat' => 0.4],
            ['name' => 'Nasi Merah', 'category' => 'Karbohidrat', 'calories' => 216, 'protein' => 5.0, 'carbohydrate' => 44.8, 'fat' => 1.8],
            ['name' => 'Nasi Goreng', 'category' => 'Karbohidrat', 'calories' => 260, 'protein' => 5.9, 'carbohydrate' => 36.1, 'fat' => 11.3],
            ['name' => 'Mie Goreng', 'category' => 'Karbohidrat', 'calories' => 320, 'protein' => 7.2, 'carbohydrate' => 48.0, 'fat' => 12.0],
            ['name' => 'Roti Gandum', 'category' => 'Karbohidrat', 'calories' => 247, 'protein' => 9.4, 'carbohydrate' => 49.0, 'fat' => 3.4],
            ['name' => 'Kentang Rebus', 'category' => 'Karbohidrat', 'calories' => 87, 'protein' => 1.9, 'carbohydrate' => 20.1, 'fat' => 0.1],
            ['name' => 'Ubi Jalar', 'category' => 'Karbohidrat', 'calories' => 86, 'protein' => 1.6, 'carbohydrate' => 20.1, 'fat' => 0.1],
            ['name' => 'Singkong Rebus', 'category' => 'Karbohidrat', 'calories' => 146, 'protein' => 1.4, 'carbohydrate' => 35.5, 'fat' => 0.3],
            ['name' => 'Oatmeal', 'category' => 'Karbohidrat', 'calories' => 389, 'protein' => 16.9, 'carbohydrate' => 66.3, 'fat' => 6.9],
            ['name' => 'Jagung Rebus', 'category' => 'Karbohidrat', 'calories' => 96, 'protein' => 3.4, 'carbohydrate' => 21.0, 'fat' => 1.5],

            // Protein Hewani
            ['name' => 'Ayam Rebus', 'category' => 'Protein', 'calories' => 165, 'protein' => 31.0, 'carbohydrate' => 0.0, 'fat' => 3.6],
            ['name' => 'Ayam Goreng', 'category' => 'Protein', 'calories' => 246, 'protein' => 29.0, 'carbohydrate' => 0.0, 'fat' => 13.8],
            ['name' => 'Daging Sapi Rebus', 'category' => 'Protein', 'calories' => 215, 'protein' => 26.0, 'carbohydrate' => 0.0, 'fat' => 11.8],
            ['name' => 'Telur Rebus', 'category' => 'Protein', 'calories' => 155, 'protein' => 13.0, 'carbohydrate' => 1.1, 'fat' => 11.0],
            ['name' => 'Telur Dadar', 'category' => 'Protein', 'calories' => 185, 'protein' => 13.6, 'carbohydrate' => 0.4, 'fat' => 14.8],
            ['name' => 'Ikan Salmon', 'category' => 'Protein', 'calories' => 208, 'protein' => 20.4, 'carbohydrate' => 0.0, 'fat' => 13.4],
            ['name' => 'Ikan Tuna', 'category' => 'Protein', 'calories' => 116, 'protein' => 25.5, 'carbohydrate' => 0.0, 'fat' => 1.0],
            ['name' => 'Ikan Lele Goreng', 'category' => 'Protein', 'calories' => 163, 'protein' => 18.5, 'carbohydrate' => 0.0, 'fat' => 9.0],
            ['name' => 'Udang Rebus', 'category' => 'Protein', 'calories' => 99, 'protein' => 18.8, 'carbohydrate' => 0.9, 'fat' => 1.8],
            ['name' => 'Ikan Bandeng', 'category' => 'Protein', 'calories' => 148, 'protein' => 20.0, 'carbohydrate' => 0.0, 'fat' => 7.2],

            // Protein Nabati
            ['name' => 'Tahu Goreng', 'category' => 'Protein', 'calories' => 76, 'protein' => 8.1, 'carbohydrate' => 1.9, 'fat' => 4.8],
            ['name' => 'Tempe Goreng', 'category' => 'Protein', 'calories' => 195, 'protein' => 18.3, 'carbohydrate' => 9.4, 'fat' => 11.4],
            ['name' => 'Tempe Bacem', 'category' => 'Protein', 'calories' => 215, 'protein' => 17.0, 'carbohydrate' => 16.0, 'fat' => 9.0],
            ['name' => 'Kacang Hijau Rebus', 'category' => 'Protein', 'calories' => 105, 'protein' => 7.2, 'carbohydrate' => 19.1, 'fat' => 0.4],
            ['name' => 'Kacang Merah', 'category' => 'Protein', 'calories' => 127, 'protein' => 8.7, 'carbohydrate' => 22.8, 'fat' => 0.5],
            ['name' => 'Kedelai Rebus', 'category' => 'Protein', 'calories' => 173, 'protein' => 16.6, 'carbohydrate' => 9.9, 'fat' => 9.0],

            // Sayuran
            ['name' => 'Bayam Rebus', 'category' => 'Sayuran', 'calories' => 23, 'protein' => 2.9, 'carbohydrate' => 3.6, 'fat' => 0.4],
            ['name' => 'Kangkung Tumis', 'category' => 'Sayuran', 'calories' => 39, 'protein' => 2.5, 'carbohydrate' => 5.0, 'fat' => 1.5],
            ['name' => 'Brokoli Rebus', 'category' => 'Sayuran', 'calories' => 34, 'protein' => 2.8, 'carbohydrate' => 6.6, 'fat' => 0.4],
            ['name' => 'Wortel Rebus', 'category' => 'Sayuran', 'calories' => 35, 'protein' => 0.8, 'carbohydrate' => 8.2, 'fat' => 0.2],
            ['name' => 'Kacang Panjang', 'category' => 'Sayuran', 'calories' => 47, 'protein' => 2.8, 'carbohydrate' => 8.4, 'fat' => 0.3],
            ['name' => 'Tauge Tumis', 'category' => 'Sayuran', 'calories' => 39, 'protein' => 3.0, 'carbohydrate' => 5.5, 'fat' => 0.9],
            ['name' => 'Timun', 'category' => 'Sayuran', 'calories' => 16, 'protein' => 0.7, 'carbohydrate' => 3.6, 'fat' => 0.1],
            ['name' => 'Tomat', 'category' => 'Sayuran', 'calories' => 18, 'protein' => 0.9, 'carbohydrate' => 3.9, 'fat' => 0.2],
            ['name' => 'Kubis Rebus', 'category' => 'Sayuran', 'calories' => 23, 'protein' => 1.3, 'carbohydrate' => 5.3, 'fat' => 0.2],
            ['name' => 'Terong Tumis', 'category' => 'Sayuran', 'calories' => 35, 'protein' => 0.8, 'carbohydrate' => 8.6, 'fat' => 0.2],

            // Buah
            ['name' => 'Pisang', 'category' => 'Buah', 'calories' => 89, 'protein' => 1.1, 'carbohydrate' => 22.8, 'fat' => 0.3],
            ['name' => 'Apel', 'category' => 'Buah', 'calories' => 52, 'protein' => 0.3, 'carbohydrate' => 13.8, 'fat' => 0.2],
            ['name' => 'Alpukat', 'category' => 'Buah', 'calories' => 160, 'protein' => 2.0, 'carbohydrate' => 8.5, 'fat' => 14.7],
            ['name' => 'Mangga', 'category' => 'Buah', 'calories' => 60, 'protein' => 0.8, 'carbohydrate' => 15.0, 'fat' => 0.4],
            ['name' => 'Semangka', 'category' => 'Buah', 'calories' => 30, 'protein' => 0.6, 'carbohydrate' => 7.6, 'fat' => 0.2],
            ['name' => 'Pepaya', 'category' => 'Buah', 'calories' => 43, 'protein' => 0.5, 'carbohydrate' => 10.8, 'fat' => 0.3],
            ['name' => 'Jeruk', 'category' => 'Buah', 'calories' => 47, 'protein' => 0.9, 'carbohydrate' => 11.8, 'fat' => 0.1],
            ['name' => 'Stroberi', 'category' => 'Buah', 'calories' => 33, 'protein' => 0.7, 'carbohydrate' => 7.7, 'fat' => 0.3],
            ['name' => 'Anggur', 'category' => 'Buah', 'calories' => 69, 'protein' => 0.7, 'carbohydrate' => 18.1, 'fat' => 0.2],

            // Susu & Olahannya
            ['name' => 'Susu Sapi', 'category' => 'Susu', 'calories' => 61, 'protein' => 3.2, 'carbohydrate' => 4.8, 'fat' => 3.3],
            ['name' => 'Yogurt Plain', 'category' => 'Susu', 'calories' => 59, 'protein' => 3.5, 'carbohydrate' => 5.0, 'fat' => 3.3],
            ['name' => 'Keju', 'category' => 'Susu', 'calories' => 402, 'protein' => 25.0, 'carbohydrate' => 1.3, 'fat' => 33.1],
            ['name' => 'Susu Kedelai', 'category' => 'Susu', 'calories' => 54, 'protein' => 3.3, 'carbohydrate' => 6.3, 'fat' => 1.8],

            // Makanan Ibu Menyusui
            ['name' => 'Sup Ayam', 'category' => 'Makanan Ibu', 'calories' => 75, 'protein' => 7.4, 'carbohydrate' => 4.8, 'fat' => 2.8],
            ['name' => 'Bubur Kacang Hijau', 'category' => 'Makanan Ibu', 'calories' => 140, 'protein' => 5.5, 'carbohydrate' => 27.0, 'fat' => 1.0],
            ['name' => 'Daun Katuk Tumis', 'category' => 'Makanan Ibu', 'calories' => 59, 'protein' => 6.4, 'carbohydrate' => 5.0, 'fat' => 2.0],
            ['name' => 'Opor Ayam', 'category' => 'Makanan Ibu', 'calories' => 185, 'protein' => 15.0, 'carbohydrate' => 5.0, 'fat' => 12.0],
            ['name' => 'Sop Buntut', 'category' => 'Makanan Ibu', 'calories' => 225, 'protein' => 18.0, 'carbohydrate' => 3.0, 'fat' => 15.0],
        ];

        foreach ($foods as $food) {
            Food::firstOrCreate(['name' => $food['name']], $food);
        }

        // ─── SUPPLEMENTS ─────────────────────────────────────────────────────
        $supplements = [
            [
                'name' => 'Vitamin D3 1000 IU',
                'composition' => 'Cholecalciferol 1000 IU',
                'packaging' => '60 tablet',
                'usage_rule' => '1 tablet per hari setelah makan',
            ],
            [
                'name' => 'Asam Folat 400 mcg',
                'composition' => 'Folic Acid 400 mcg',
                'packaging' => '30 tablet',
                'usage_rule' => '1 tablet per hari bersama makanan',
            ],
            [
                'name' => 'Kalsium 500 mg',
                'composition' => 'Calcium Carbonate 500 mg, Vitamin D3 200 IU',
                'packaging' => '60 tablet',
                'usage_rule' => '1-2 tablet per hari',
            ],
            [
                'name' => 'Zat Besi 60 mg',
                'composition' => 'Ferrous Sulfate 60 mg',
                'packaging' => '30 tablet',
                'usage_rule' => '1 tablet per hari, diminum dengan air putih atau jus jeruk',
            ],
            [
                'name' => 'Vitamin C 500 mg',
                'composition' => 'Ascorbic Acid 500 mg',
                'packaging' => '60 tablet',
                'usage_rule' => '1 tablet per hari setelah makan',
            ],
            [
                'name' => 'Omega-3 Fish Oil',
                'composition' => 'EPA 180 mg, DHA 120 mg',
                'packaging' => '30 kapsul',
                'usage_rule' => '1-2 kapsul per hari bersama makanan',
            ],
            [
                'name' => 'Vitamin B12 500 mcg',
                'composition' => 'Cyanocobalamin 500 mcg',
                'packaging' => '30 tablet',
                'usage_rule' => '1 tablet per hari',
            ],
            [
                'name' => 'Magnesium 250 mg',
                'composition' => 'Magnesium Citrate 250 mg',
                'packaging' => '60 kapsul',
                'usage_rule' => '1 kapsul per hari sebelum tidur',
            ],
            [
                'name' => 'Zinc 10 mg',
                'composition' => 'Zinc Gluconate 10 mg',
                'packaging' => '60 tablet',
                'usage_rule' => '1 tablet per hari bersama makanan',
            ],
            [
                'name' => 'Probiotik Lactobasillus',
                'composition' => 'Lactobacillus acidophilus 1 billion CFU, Bifidobacterium 500 million CFU',
                'packaging' => '30 kapsul',
                'usage_rule' => '1 kapsul per hari sebelum makan',
            ],
            [
                'name' => 'Vitamin E 400 IU',
                'composition' => 'dl-Alpha Tocopherol 400 IU',
                'packaging' => '30 kapsul',
                'usage_rule' => '1 kapsul per hari bersama makanan',
            ],
            [
                'name' => 'Multivitamin Ibu Menyusui',
                'composition' => 'Vitamin A, C, D, E, B1, B6, B12, Asam Folat, Zat Besi, Kalsium, Zinc, Iodium',
                'packaging' => '30 tablet',
                'usage_rule' => '1 tablet per hari setelah makan',
            ],
            [
                'name' => 'Kolagen Peptida',
                'composition' => 'Hydrolyzed Collagen 5000 mg',
                'packaging' => '30 sachet',
                'usage_rule' => '1 sachet per hari, larutkan dalam 200 ml air',
            ],
            [
                'name' => 'Iodium 150 mcg',
                'composition' => 'Potassium Iodide 150 mcg',
                'packaging' => '60 tablet',
                'usage_rule' => '1 tablet per hari',
            ],
            [
                'name' => 'Vitamin A 5000 IU',
                'composition' => 'Retinyl Palmitate 5000 IU',
                'packaging' => '30 kapsul',
                'usage_rule' => '1 kapsul per hari bersama makanan berlemak',
            ],
        ];

        foreach ($supplements as $supp) {
            \App\Models\Supplement::firstOrCreate(['name' => $supp['name']], $supp);
        }

        $this->command->info('Food and Supplement data seeded successfully!');
    }
}
