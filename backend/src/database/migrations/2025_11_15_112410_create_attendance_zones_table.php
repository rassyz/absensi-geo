<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::statement('CREATE EXTENSION IF NOT EXISTS postgis');

        Schema::create('attendance_zones', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            // Kolom GEOMETRY untuk poligon/radius
            $table->geometry('area', srid: 4326); // SRID 4326 untuk GPS coordinates
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('attendance_zones');
    }
};
