import SwiftUI

struct VisitPointView: View {
    @StateObject private var viewModel = VisitPointViewModel()

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.loading && viewModel.deliveries.isEmpty {
                Spacer()
                ProgressView("Cargando puntos...")
                    .tint(CaleiColors.accent)
                Spacer()
            } else {
                deliverySelector
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                if let feedback = viewModel.feedbackMessage {
                    Text(feedback)
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.success)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                }

                if viewModel.sortedItems.isEmpty {
                    Spacer()
                    Text("No hay puntos para visitar en este reparto.")
                        .font(CaleiTypography.body)
                        .foregroundColor(CaleiColors.gray500)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.sortedItems) { item in
                                VisitPointCard(
                                    item: item,
                                    isSubmitting: viewModel.submittingItemIds.contains(item.id),
                                    isArrived: viewModel.arrivedItemIds.contains(item.id),
                                    onArrived: {
                                        Task { await viewModel.arrived(item: item) }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .background(CaleiColors.background)
        .navigationTitle("Visitar Punto")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadInitial()
        }
    }

    private var deliverySelector: some View {
        Menu {
            if viewModel.deliveries.isEmpty {
                Text("Sin repartos disponibles")
            } else {
                ForEach(viewModel.deliveries) { delivery in
                    Button {
                        Task { await viewModel.selectDelivery(delivery.id) }
                    } label: {
                        HStack {
                            Text(delivery.displayTitle)
                            if viewModel.selectedDeliveryId == delivery.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reparto")
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)
                    Text(selectedDeliveryLabel)
                        .font(CaleiTypography.body)
                        .foregroundColor(CaleiColors.dark)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(CaleiColors.gray500)
            }
            .padding(12)
            .background(CaleiColors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CaleiColors.gray200, lineWidth: 1)
            )
        }
    }

    private var selectedDeliveryLabel: String {
        guard let selectedDeliveryId,
              let selected = viewModel.deliveries.first(where: { $0.id == selectedDeliveryId }) else {
            return "Seleccioná un reparto"
        }
        return selected.displayTitle
    }
}

private struct VisitPointCard: View {
    let item: DeliveryItem
    let isSubmitting: Bool
    let isArrived: Bool
    let onArrived: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(CaleiTypography.body)
                        .foregroundColor(CaleiColors.dark)

                    Text(routeOrderText)
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)
                }

                Spacer()

                statusBadge
            }

            Button {
                onArrived()
            } label: {
                HStack(spacing: 6) {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                    Text(isArrived ? "Llegada registrada" : "Llegué")
                        .font(CaleiTypography.buttonSmall)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isArrived ? CaleiColors.success : CaleiColors.accent)
                .cornerRadius(10)
            }
            .disabled(isSubmitting || isArrived)
            .opacity((isSubmitting || isArrived) ? 0.8 : 1)
        }
        .padding(12)
        .background(CaleiColors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(CaleiColors.gray200, lineWidth: 1)
        )
    }

    private var routeOrderText: String {
        if let route = item.routeOrder {
            return "Orden de ruta #\(route)"
        }
        return "Sin orden de ruta"
    }

    @ViewBuilder
    private var statusBadge: some View {
        Text(item.itemStatus.displayName)
            .font(CaleiTypography.caption)
            .foregroundColor(item.itemStatus.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(item.itemStatus.color.opacity(0.14))
            .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        VisitPointView()
    }
}
