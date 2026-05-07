<div wire:ignore>
    <div
        x-data="{
            map: null,
            areaData: @js($getRecord()->area),

            init() {
                if (!document.getElementById('leaflet-css')) {
                    let link = document.createElement('link');
                    link.id = 'leaflet-css';
                    link.rel = 'stylesheet';
                    link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
                    document.head.appendChild(link);
                }

                this.loadScript('https://unpkg.com/leaflet@1.9.4/dist/leaflet.js', 'L')
                    .then(() => this.loadScript('https://cdn.jsdelivr.net/npm/@turf/turf@6/turf.min.js', 'turf'))
                    .then(() => {
                        this.drawMap();
                    })
                    .catch(err => console.error('Gagal memuat skrip peta:', err));
            },

            loadScript(src, globalVar) {
                return new Promise((resolve, reject) => {
                    if (typeof window[globalVar] !== 'undefined') {
                        resolve();
                        return;
                    }
                    let script = document.createElement('script');
                    script.src = src;
                    script.onload = () => resolve();
                    script.onerror = () => reject(new Error('Gagal memuat ' + src));
                    document.head.appendChild(script);
                });
            },

            drawMap() {
                if (!this.areaData) return;

                // Pastikan format data dibaca sebagai Objek JSON yang valid
                let geoData = typeof this.areaData === 'string' ? JSON.parse(this.areaData) : this.areaData;

                if (this.map) {
                    this.map.remove();
                }

                this.map = L.map(this.$refs.mapContainer).setView([0, 0], 13);

                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    attribution: '© OpenStreetMap',
                    maxZoom: 19
                }).addTo(this.map);

                let mainLayer = null;

                try {
                    // 1. Menggambar zona toleransi 10 meter (Merah Putus-putus)
                    const buffered = turf.buffer(geoData, 0.01, { units: 'kilometers' });
                    L.geoJSON(buffered, {
                        style: {
                            color: '#ef4444',
                            weight: 2,
                            dashArray: '5, 5',
                            fillColor: '#ef4444',
                            fillOpacity: 0.1
                        }
                    }).addTo(this.map).bindPopup('Zona Toleransi GPS (10 Meter)');
                } catch(e) {
                    console.error('Terjadi kesalahan pada Turf.js:', e);
                }

                try {
                    // 2. Menggambar zona asli (Biru)
                    mainLayer = L.geoJSON(geoData, {
                        style: {
                            color: '#3b82f6',
                            weight: 3,
                            fillColor: '#3b82f6',
                            fillOpacity: 0.3
                        }
                    }).addTo(this.map).bindPopup('Area Inti Presensi');
                } catch(e) {
                    console.error('Terjadi kesalahan pada Leaflet GeoJSON:', e);
                }

                // 👇 PERBAIKAN KRUSIAL: Taruh perhitungan zoom ke dalam jeda waktu 400ms
                // Menunggu animasi modal Filament terbuka secara sempurna agar ukurannya 100% akurat
                setTimeout(() => {
                    // Refresh ukuran peta
                    this.map.invalidateSize();

                    // Fokuskan kamera ke poligon
                    if (mainLayer) {
                        this.map.fitBounds(mainLayer.getBounds(), { padding: [20, 20] });
                    }
                }, 400);
            }
        }"
        style="height: 400px; width: 100%; border-radius: 0.5rem; border: 1px solid #e5e7eb; position: relative;"
    >
        <div x-ref="mapContainer" style="height: 100%; width: 100%; border-radius: 0.5rem; z-index: 1;"></div>
    </div>
</div>
