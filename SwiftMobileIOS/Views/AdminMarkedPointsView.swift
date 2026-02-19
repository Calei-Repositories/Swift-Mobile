import SwiftUI

struct AdminMarkedPointsView: View {
    @StateObject private var viewModel = AdminMarkedPointsViewModel()

    var body: some View {
        List {
            Section(header: Text("Zonas")) {
                ForEach(viewModel.zones) { zone in
                    Text("Zona \(zone.zoneId.map(String.init) ?? "Sin zona"): \(zone.count)")
                }
            }

            Section(header: Text("Puntos")) {
                ForEach(viewModel.points) { point in
                    VStack(alignment: .leading) {
                        Text(point.name)
                        Text("\(point.latitude), \(point.longitude)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Puntos marcados")
        .task {
            await viewModel.loadZones()
            await viewModel.loadPoints()
        }
    }
}
