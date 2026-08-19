@php
    $checkInLat = $record?->check_in_latitude
        ? (float) $record->check_in_latitude
        : null;

    $checkInLng = $record?->check_in_longitude
        ? (float) $record->check_in_longitude
        : null;

    $checkOutLat = $record?->check_out_latitude
        ? (float) $record->check_out_latitude
        : null;

    $checkOutLng = $record?->check_out_longitude
        ? (float) $record->check_out_longitude
        : null;

    /**
     * Membuat URL embed OpenStreetMap
     * dengan marker pada koordinat presensi.
     */
    $makeOsmEmbedUrl = function (?float $lat, ?float $lng): ?string {
        if ($lat === null || $lng === null) {
            return null;
        }

        // Area sekitar titik agar map tidak terlalu zoom out.
        $offset = 0.003;

        $bbox = implode(',', [
            $lng - $offset,
            $lat - $offset,
            $lng + $offset,
            $lat + $offset,
        ]);

        return 'https://www.openstreetmap.org/export/embed.html?' .
            http_build_query([
                'bbox' => $bbox,
                'layer' => 'mapnik',
                'marker' => $lat . ',' . $lng,
            ]);
    };

    $makeOsmPageUrl = function (?float $lat, ?float $lng): ?string {
        if ($lat === null || $lng === null) {
            return null;
        }

        return sprintf(
            'https://www.openstreetmap.org/?mlat=%s&mlon=%s#map=18/%s/%s',
            $lat,
            $lng,
            $lat,
            $lng,
        );
    };

    $checkInMap = $makeOsmEmbedUrl(
        $checkInLat,
        $checkInLng,
    );

    $checkOutMap = $makeOsmEmbedUrl(
        $checkOutLat,
        $checkOutLng,
    );

    $checkInUrl = $makeOsmPageUrl(
        $checkInLat,
        $checkInLng,
    );

    $checkOutUrl = $makeOsmPageUrl(
        $checkOutLat,
        $checkOutLng,
    );
@endphp


@if ($checkInMap || $checkOutMap)

    <div class="space-y-4">

        <div>
            <h3 class="text-sm font-semibold text-gray-950 dark:text-white">
                Lokasi Presensi
            </h3>

            <p class="text-sm text-gray-500 dark:text-gray-400">
                Titik GPS aktual yang direkam saat karyawan melakukan presensi.
            </p>
        </div>


        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">

            {{-- CHECK-IN --}}
            @if ($checkInMap)
                <div
                    class="overflow-hidden rounded-xl border border-gray-200 dark:border-white/10"
                >
                    <div class="border-b border-gray-200 p-3 dark:border-white/10">
                        <div class="font-medium text-gray-950 dark:text-white">
                            Lokasi Check-In
                        </div>

                        <div class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                            {{ number_format($checkInLat, 8) }},
                            {{ number_format($checkInLng, 8) }}
                        </div>
                    </div>

                    <iframe
                        src="{{ $checkInMap }}"
                        class="h-72 w-full border-0"
                        loading="lazy"
                        title="Lokasi Check-In OpenStreetMap"
                    ></iframe>

                    <div class="p-3">
                        <a
                            href="{{ $checkInUrl }}"
                            target="_blank"
                            rel="noopener noreferrer"
                            class="text-sm font-medium text-primary-600 hover:underline dark:text-primary-400"
                        >
                            Buka di OpenStreetMap
                        </a>
                    </div>
                </div>
            @endif


            {{-- CHECK-OUT --}}
            @if ($checkOutMap)
                <div
                    class="overflow-hidden rounded-xl border border-gray-200 dark:border-white/10"
                >
                    <div class="border-b border-gray-200 p-3 dark:border-white/10">
                        <div class="font-medium text-gray-950 dark:text-white">
                            Lokasi Check-Out
                        </div>

                        <div class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                            {{ number_format($checkOutLat, 8) }},
                            {{ number_format($checkOutLng, 8) }}
                        </div>
                    </div>

                    <iframe
                        src="{{ $checkOutMap }}"
                        class="h-72 w-full border-0"
                        loading="lazy"
                        title="Lokasi Check-Out OpenStreetMap"
                    ></iframe>

                    <div class="p-3">
                        <a
                            href="{{ $checkOutUrl }}"
                            target="_blank"
                            rel="noopener noreferrer"
                            class="text-sm font-medium text-primary-600 hover:underline dark:text-primary-400"
                        >
                            Buka di OpenStreetMap
                        </a>
                    </div>
                </div>
            @endif

        </div>
    </div>

@else

    <div
        class="rounded-xl border border-gray-200 p-4 dark:border-white/10"
    >
        <p class="text-sm text-gray-500 dark:text-gray-400">
            Data koordinat lokasi presensi tidak tersedia.
        </p>
    </div>

@endif
