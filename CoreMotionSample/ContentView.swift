//
//  ContentView.swift
//  CoreMotionSample
//  Created by Jason on 5/13/24.
//

import SwiftUI
import CoreMotion
import Charts


class ContentViewModel: ObservableObject {
    @Published var segmentTitles: [String] = ["User Accelerometer", "RotationRate", "Quaternion" ]
    @Published var currentSegmentIndex = 0
}

struct ContentView: View {
    @State private var showOnboarding = true
    @ObservedObject var viewModel = ContentViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var UserAccelX = 0.0
    @State private var UserAccelY = 0.0
    @State private var UserAccelZ = 0.0
    @State private var RotationRateX = 0.0
    @State private var RotationRateY = 0.0
    @State private var RotationRateZ = 0.0
    @State private var QuaternionX = 0.0
    @State private var QuaternionY = 0.0
    @State private var QuaternionZ = 0.0
    @State private var dataPoints: [(ax: Double, ay: Double, az: Double, rx: Double, ry: Double, rz: Double, qx: Double, qy: Double, qz: Double)] = []
    
    private let motionManager = CMMotionManager()
    private let lineWidth: CGFloat = 2
    private let symbolSize: CGFloat = 6
    
    var body: some View {
        
        
        VStack {
            Picker("Sensor Type", selection: $viewModel.currentSegmentIndex) {
                ForEach(0..<viewModel.segmentTitles.count, id: \.self) { index in
                    Text(self.viewModel.segmentTitles[index])
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            Text("\(viewModel.segmentTitles[viewModel.currentSegmentIndex]) Data")
            VStack {
                Group {
                    if viewModel.currentSegmentIndex == 0 {
                        Text("X: \(UserAccelX)")
                        Text("Y: \(UserAccelY)")
                        Text("Z: \(UserAccelZ)")
                    } else if viewModel.currentSegmentIndex == 1 {
                        Text("X: \(RotationRateX)")
                        Text("Y: \(RotationRateY)")
                        Text("Z: \(RotationRateZ)")
                    } else if viewModel.currentSegmentIndex == 2 {
                        Text("X: \(QuaternionX)")
                        Text("Y: \(QuaternionY)")
                        Text("Z: \(QuaternionZ)")
                    }
                }
            }
            VStack {
                Chart {
                    ForEach(dataPoints.indices, id: \.self) { index in
                        let dataPoint = dataPoints[index]
                        let values = viewModel.currentSegmentIndex == 0 ? (dataPoint.ax, dataPoint.ay, dataPoint.az) :
                        viewModel.currentSegmentIndex == 1 ? (dataPoint.rx, dataPoint.ry, dataPoint.rz) :
                        (dataPoint.qx, dataPoint.qy, dataPoint.qz)
                        LineMark(
                            x: .value("Index", index),
                            y: .value("X Value", values.0)
                        )
                        .foregroundStyle(by: .value("X", "X Axis"))
                        .symbol(by: .value("X", "X Axis"))
                        
                        LineMark(
                            x: .value("Index", index),
                            y: .value("Y Value", values.1)
                        )
                        .foregroundStyle(by: .value("Y", "Y Axis"))
                        .symbol(by: .value("Y", "Y Axis"))
                        
                        LineMark(
                            x: .value("Index", index),
                            y: .value("Z Value", values.2)
                        )
                        .foregroundStyle(by: .value("Z", "Z Axis"))
                        .symbol(by: .value("Z", "Z Axis"))
                        
                    }
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: lineWidth))
                    .symbolSize(symbolSize)
                }
                .chartForegroundStyleScale([
                    "X Axis": .red,
                    "Y Axis": .green,
                    "Z Axis": .blue
                ])
                .chartLegend(position: .bottom, alignment: .center)
                
                HStack {
                    Button("Start") {
                        startRecordingDeviceMotion()
                    }
                    .font(.body)
                    .foregroundColor(.green)
                    Button("Stop") {
                        stopRecordingDeviceMotion()
                    }
                    .font(.body)
                    .foregroundColor(.red)
                }
            }
        }
        .onChange(of: scenePhase) {
            handleSceneChange()
        }
        
    }
}

extension ContentView {
    func startRecordingDeviceMotion() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion data is not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { (deviceMotion, error) in
            guard let data = deviceMotion, error == nil else {
                print("Failed to get device motion data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            let acceleration = data.userAcceleration
            let rotationRate = data.rotationRate
            let quaternion = data.attitude.quaternion
            
            
            UserAccelX = acceleration.x
            UserAccelY = acceleration.y
            UserAccelZ = acceleration.z
            
            RotationRateX = rotationRate.x
            RotationRateY = rotationRate.y
            RotationRateZ = rotationRate.z
            
            QuaternionX = quaternion.x
            QuaternionY = quaternion.y
            QuaternionZ = quaternion.z
            
            
            
            
            dataPoints.append((ax: UserAccelX, ay: UserAccelY, az: UserAccelZ, rx: RotationRateX, ry: RotationRateY, rz: RotationRateZ, qx: QuaternionX, qy: QuaternionY, qz: QuaternionZ))
            
            if dataPoints.count > 100 { // 큐 버킷 사이즈 100
                dataPoints.removeFirst()
            }
        }
    }
    
    func stopRecordingDeviceMotion() {
        motionManager.stopDeviceMotionUpdates()
        print("Motion updates stopped")
    }
    //백그라운드 진입시 모션센서 레코드 정지
    private func handleSceneChange() {
        switch scenePhase {
        case .active:
            print("App is active")
        case .background:
            print("App is in background")
            stopRecordingDeviceMotion()
        case .inactive:
            print("App is inactive")
        @unknown default:
            break
        }
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

