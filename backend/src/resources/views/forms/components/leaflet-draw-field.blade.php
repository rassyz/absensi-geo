@once
    @push('scripts')
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet.draw/1.0.4/leaflet.draw.css" />
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet.draw/1.0.4/leaflet.draw.js"></script>
    @endpush
@endonce

<x-filament-forms::field-wrapper :field="$field">
    <div
        x-data="{
            state: $wire.$entangle('{{ $getStatePath() }}'),
            map: null,
            drawnItems: null,
            initMap() {
                this.map = L.map($refs.map).setView([-6.200000, 106.816666], 13);
                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {}).addTo(this.map);

                this.drawnItems = new L.FeatureGroup();
                this.map.addLayer(this.drawnItems);

                const drawControl = new L.Control.Draw({
                    edit: { featureGroup: this.drawnItems },
                    draw: { polygon: true, circle: true, rectangle: true },
                });
                this.map.addControl(drawControl);

                if (this.state) {
                    try {
                        const geojsonLayer = L.geoJSON(JSON.parse(this.state));
                        geojsonLayer.eachLayer((layer) => this.drawnItems.addLayer(layer));
                        this.map.fitBounds(this.drawnItems.getBounds());
                    } catch (e) {
                        console.error('Invalid GeoJSON:', this.state);
                    }
                }

                this.map.on(L.Draw.Event.CREATED, (e) => {
                    this.drawnItems.clearLayers();
                    this.drawnItems.addLayer(e.layer);
                    this.updateState();
                });

                this.map.on(L.Draw.Event.EDITED, () => this.updateState());

                this.map.on(L.Draw.Event.DELETED, () => {
                    this.state = null;
                });
            },
            updateState() {
                const geojson = this.drawnItems.toGeoJSON();
                this.state =
                    geojson.features.length > 0
                        ? JSON.stringify(geojson.features[0].geometry)
                        : null;
            }
        }"
        x-init="initMap()"
        wire:ignore
    >
        <div x-ref="map" style="height: 600px; width: 100%; border-radius: 8px;"></div>
    </div>
</x-filament-forms::field-wrapper>
