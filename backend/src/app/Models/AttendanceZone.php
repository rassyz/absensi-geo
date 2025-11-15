<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use App\Models\Department;

class AttendanceZone extends Model
{
    protected $fillable = [
        'name',
        'area',
    ];

    // Relasi Many-to-Many dengan Department
    public function departments()
    {
        return $this->belongsToMany(Department::class, 'department_attendance_zone');
    }
    // Konverter Otomatis GeoJSON <-> PostGIS
    protected function area(): Attribute
    {
        return Attribute::make(
            get: function ($value) {
                if (is_null($value)) return null;
                $result = DB::selectOne("SELECT ST_AsGeoJSON(?) AS geojson", [$value]);
                return $result->geojson;
            },
            set: function ($value) {
                if (is_null($value) || $value === '') return null;
                // ST_SetSRID(..., 4326) memastikan data disimpan dalam format GPS
                return DB::raw("ST_SetSRID(ST_GeomFromGeoJSON('$value'), 4326)");
            }
        );
    }
}
