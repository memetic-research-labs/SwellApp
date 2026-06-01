import SwiftUI
import MapKit
import CoreLocation

@MainActor
@Observable
final class AddBeachViewModel {
    private let spotDB = SurfSpotDatabase()
    private let store: BeachStoring
    private let coastlineService: CoastlineBearingService
    var searchQuery = ""
    var searchResults: [SurfSpot] = []
    var selectedCoordinate: CLLocationCoordinate2D?
    var beachBearing: Double = 270
    var bearingAutoDetected = false
    var beachName = ""
    var isSaving = false
    var isDetectingBearing = false
    var userLocation: CLLocationCoordinate2D?
    var locationAuthorized = false
    var locationError: String?

    private let locationManager = CLLocationManager()
    private var locationDelegate: LocationDelegate?

    init(store: BeachStoring = FileBeachStore(),
         coastlineService: CoastlineBearingService = CoastlineBearingService()) {
        self.store = store
        self.coastlineService = coastlineService
        let delegate = LocationDelegate(
            onLocation: { [weak self] location in
                self?.handleLocationUpdate(location)
                if self?.selectedCoordinate == nil {
                    self?.selectedCoordinate = location.coordinate
                }
            },
            onError: { [weak self] error in
                self?.handleLocationError(error)
            }
        )
        self.locationDelegate = delegate
        locationManager.delegate = delegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 33.5, longitude: -117.5),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    ))

    func requestLocation() {
        locationManager.requestLocation()
        if let loc = userLocation {
            withAnimation(.easeInOut(duration: 0.5)) {
                mapPosition = .region(MKCoordinateRegion(
                    center: loc,
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                ))
            }
        }
    }

    func handleLocationUpdate(_ location: CLLocation) {
        userLocation = location.coordinate
        locationAuthorized = true
        mapPosition = .region(MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        ))
    }

    func handleLocationError(_ error: Error) {
        locationError = error.localizedDescription
    }

    func search() {
        do {
            searchResults = try spotDB.search(searchQuery)
        } catch {
            searchResults = []
        }
    }

    func select(_ spot: SurfSpot) {
        selectedCoordinate = CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)
        beachBearing = spot.bearing
        beachName = spot.name
        searchQuery = ""
        searchResults = []
        detectBearingIfNeeded()
    }

    func handleCoordinateChange(_ coord: CLLocationCoordinate2D) {
        selectedCoordinate = coord
        detectBearingIfNeeded()
    }

    func save() async -> Beach? {
        guard let coord = selectedCoordinate, !beachName.isEmpty else { return nil }
        let beach = Beach(
            name: beachName,
            latitude: coord.latitude,
            longitude: coord.longitude,
            bearing: beachBearing
        )
        isSaving = true
        do {
            try await store.save(beach)
            return beach
        } catch {
            return nil
        }
    }

    private func detectBearingIfNeeded() {
        guard let coord = selectedCoordinate else { return }
        isDetectingBearing = true
        bearingAutoDetected = false
        Task {
            defer { isDetectingBearing = false }
            if let detected = await coastlineService.detectBearing(lat: coord.latitude, lon: coord.longitude) {
                beachBearing = detected
                bearingAutoDetected = true
            }
        }
    }
}

final class LocationDelegate: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private let onLocation: @MainActor (CLLocation) -> Void
    private let onError: @MainActor (Error) -> Void

    init(onLocation: @escaping @MainActor (CLLocation) -> Void,
         onError: @escaping @MainActor (Error) -> Void) {
        self.onLocation = onLocation
        self.onError = onError
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in onLocation(location) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in onError(error) }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }
}

struct AddBeachView: View {
    @State private var viewModel = AddBeachViewModel()
    @State private var showNamePrompt = false
    var onSaved: ((Beach) -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                ZStack(alignment: .bottom) {
                    mapView
                    VStack(spacing: 8) {
                        if viewModel.selectedCoordinate != nil {
                            bearingEditor
                        } else {
                            dropPinHint
                        }
                    }
                }
                .overlay(alignment: .topTrailing) {
                    locationButton
                }
            }
            .navigationTitle("Add Beach")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear { viewModel.requestLocation() }
        }
    }

    var locationButton: some View {
        Button {
            viewModel.requestLocation()
        } label: {
            Image(systemName: "location.fill")
                .font(.title3)
                .padding(10)
                .background(.regularMaterial)
                .clipShape(Circle())
                .shadow(radius: 2)
        }
        .padding(.trailing, 12)
        .padding(.top, 12)
    }

    var searchBar: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search spots...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .onSubmit { viewModel.search() }
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                        viewModel.searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(.regularMaterial)

            if !viewModel.searchResults.isEmpty {
                List(viewModel.searchResults) { spot in
                    Button {
                        viewModel.select(spot)
                        withAnimation(.easeInOut(duration: 0.5)) {
                            viewModel.mapPosition = .region(MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude),
                                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                            ))
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(spot.name).font(.headline)
                            Text(spot.region).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }

    var mapView: some View {
        MapReader { proxy in
            Map(position: $viewModel.mapPosition) {
                if let coord = viewModel.selectedCoordinate {
                    Marker(viewModel.beachName.isEmpty ? "Drop Pin" : viewModel.beachName, coordinate: coord)
                }
                if viewModel.userLocation != nil {
                    UserAnnotation()
                }
            }
            .mapStyle(.hybrid)
            .onTapGesture { screenCoord in
                if let coord = proxy.convert(screenCoord, from: .local) {
                    viewModel.handleCoordinateChange(coord)
                }
            }
            .onMapCameraChange(frequency: .continuous) { context in
                viewModel.mapPosition = .region(context.region)
            }
        }
    }

    var dropPinHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
            Text("Tap the map to drop a pin")
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.bottom, 40)
    }

    var bearingEditor: some View {
        VStack(spacing: 12) {
            Text("Beach faces")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            bearingDial

            Button("Save Beach") {
                showNamePrompt = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 40)
        }
        .alert("Name Your Beach", isPresented: $showNamePrompt) {
            TextField("Name", text: $viewModel.beachName)
            Button("Save") {
                Task {
                    if let beach = await viewModel.save() {
                        onSaved?(beach)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    var bearingDial: some View {
        let dialSize: CGFloat = 120

        return ZStack {
            Circle()
                .fill(.regularMaterial)
                .frame(width: dialSize, height: dialSize)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)

            Circle()
                .stroke(.primary.opacity(0.12), lineWidth: 1)
                .frame(width: dialSize, height: dialSize)

            ArrowHead()
                .fill(.primary.opacity(0.6))
                .frame(width: 12, height: 16)
                .offset(y: -(dialSize / 2 - 24))
                .rotationEffect(.degrees(viewModel.beachBearing))

            VStack(spacing: 0) {
                if viewModel.isDetectingBearing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("\(Int(viewModel.beachBearing))°")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(CompassAngle.format(viewModel.beachBearing))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    if viewModel.bearingAutoDetected {
                        Text("GPS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.green))
                            .padding(.top, 2)
                    }
                }
            }

            HStack(spacing: 0) {
                Button {
                    viewModel.beachBearing = CompassAngle.normalize(viewModel.beachBearing - 15)
                } label: {
                    Color.clear
                        .frame(width: dialSize / 2, height: dialSize)
                        .contentShape(Rectangle())
                }
                Button {
                    viewModel.beachBearing = CompassAngle.normalize(viewModel.beachBearing + 15)
                } label: {
                    Color.clear
                        .frame(width: dialSize / 2, height: dialSize)
                        .contentShape(Rectangle())
                }
            }
        }
        .frame(width: dialSize, height: dialSize)
    }
}

struct ArrowHead: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY * 0.7))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}