import SwiftUI

struct SkyHarborLoadingScreen: View {
    @State private var pulse = false
    @State private var sweep = false

    var body: some View {
        ZStack {
            Brand.navy.edgesIgnoringSafeArea(.all)

            VStack(spacing: 26) {
                ZStack {
                    Circle()
                        .stroke(Brand.skyDim.opacity(0.4), lineWidth: 2)
                        .frame(width: 110, height: 110)
                    Circle()
                        .trim(from: 0, to: 0.28)
                        .stroke(Brand.sky, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(sweep ? 360 : 0))
                        .animation(.linear(duration: 1.6).repeatForever(autoreverses: false), value: sweep)
                    PlaneShape()
                        .fill(Brand.jet)
                        .frame(width: 46, height: 46)
                        .scaleEffect(pulse ? 1.08 : 0.92)
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
                }

                Text("SKY HARBOR")
                    .font(.system(size: 24, weight: .heavy))
                    .tracking(4)
                    .foregroundColor(Brand.jet)
                Text("T Y C O O N")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(6)
                    .foregroundColor(Brand.sky)
            }
        }
        .onAppear { pulse = true; sweep = true }
    }
}
