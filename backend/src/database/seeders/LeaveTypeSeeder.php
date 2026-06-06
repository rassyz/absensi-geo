<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class LeaveTypeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $leaveTypes = [
            ['code' => 'ANNUAL', 'name' => 'Cuti Tahunan', 'is_active' => true],
            ['code' => 'MARRIAGE', 'name' => 'Cuti Menikah', 'is_active' => true],
            ['code' => 'MATERNITY', 'name' => 'Cuti Melahirkan', 'is_active' => true],
            ['code' => 'BEREAVEMENT', 'name' => 'Cuti Kedukaan', 'is_active' => true],
            ['code' => 'SICK', 'name' => 'Cuti Sakit', 'is_active' => true],
        ];

        DB::table('leave_types')->insert($leaveTypes);
    }
}
