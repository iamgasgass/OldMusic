//
//  Common.swift
//  OldMusic
//
//  Extracted verbatim from OldOS (Common.swift / HomeScreen.swift / Weather.swift)
//  by Zane Kleinberg. Only the UI building blocks used by the iPod app are kept here.
//
//  Changes vs. original (bug fixes only, visuals untouched):
//   - configureNetworkMonitor no longer creates a brand-new NWPathMonitor every second
//     (it leaked one monitor + one thread per tick) and now calls back on the main thread.
//   - CustomSlider ("Song" type) seeks on the main thread, once, when the drag ends, so the
//     knob no longer jumps back and the player is not hammered from a background queue.
//   - MPVolumeView.setVolume uses one persistent, hidden MPVolumeView living in the window
//     (a detached MPVolumeView does not reliably change the system volume on modern iOS).
//

import SwiftUI
import CoreTelephony
import PureSwiftUITools
import Foundation
import MediaPlayer
import AVFoundation
import Network

//So what is this entire file just called common? Basically, my mindset was to build the app in the same way Apple built interface builder — you have a collection of UI elements at your disposal that are bases. You can then make a copy in whatever other file you'd like if you require custom abilities. If you just need the generic version, you can use the generic.

//MARK: - Carrier helper

func oldmusic_carrier_name() -> String {
    let networkInfo = CTTelephonyNetworkInfo()
    let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value
    let carrierName = carrier?.carrierName ?? ""
    if carrierName == "" && UIDevice.current.userInterfaceIdiom == .pad {
        return "iPad"
    }
    return carrierName
}

//In App Status Bar

struct status_bar_in_app: View {
    @State var date = Date()
    var locked = false
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var battery_level = UIDevice.current.batteryLevel * 100
    @State var carrier_id: String = oldmusic_carrier_name()
    @State var charging: Bool = false
    var selected_page = 1
    @State var wifi_connected : Bool = true
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.init(red: 237/255, green: 244/255, blue: 247/255), Color.init(red: 191/255, green: 199/255, blue: 203/255)]), startPoint: UnitPoint(x: 0.5, y: 0.07), endPoint: .bottom).innerShadowBottomView(color: Color.init(red: 142/255, green: 149/255, blue: 154/255), radius: 0.05).border_bottom(width: 0.45, edges:[.bottom], color: Color.init(red: 93/255, green: 100/255, blue: 105/255)).cornerRadiusSpecific(radius: 1.75, corners: [.topLeft, .topRight])
            HStack {
                Text(carrier_id == "" ? "No SIM" : carrier_id == "--" ? "eSIM" : carrier_id).foregroundColor(carrier_id == "" ? .black : Color.init(red: 66/255, green: 66/255, blue: 66/255)).font(.custom("Helvetica Neue Bold", fixedSize: 15)).shadowStyle().onAppear() {
                    carrier_id = oldmusic_carrier_name()
                }
                ZStack {
                    Image(systemName: "wifi").gradientForegroundNonDynamic(colors: [Color.init(red: 32/255, green: 157/255, blue: 237/255), Color.init(red: 72/255, green: 118/255, blue: 196/255)]) .opacity(wifi_connected ? 1 : 0).shadowStyle().mask( Image(systemName: "wifi").gradientForegroundNonDynamic(colors: [Color.init(red: 32/255, green: 157/255, blue: 237/255), Color.init(red: 72/255, green: 118/255, blue: 196/255)]) .opacity(wifi_connected ? 1 : 0).shadowStyle().innerShadow2(color: Color.black.opacity(0.8), radius: 1))//Is it messy, yes, does it work, yes
                }
                Spacer()
                Text("\(Int(battery_level))%").foregroundColor(Color.init(red: 74/255, green: 74/255, blue: 74/255)).font(.custom("Helvetica Neue Bold", fixedSize: 15)).shadowStyle().offset(x: 10).isHidden(charging)
                battery_in_app(battery: Float(battery_level/100), charging: charging)
                    .onReceive(timer) { input in
                        if (UIDevice.current.batteryState != .unplugged) {
                            battery_level = 100
                            charging = true
                        } else {
                            battery_level = UIDevice.current.batteryLevel * 100
                            charging = false
                        }
                        date = Date()
                        if carrier_id == "" {
                            carrier_id = oldmusic_carrier_name()
                        }
                        configureNetworkMonitor(completion: {result in
                            wifi_connected = result
                        })
                    }.offset(x: 5)
                //Spacer()
            }.padding([.leading, .trailing], 4)
            HStack {
                Spacer()
                Text(timeString(date: date).uppercased()).foregroundColor(Color.black).font(.custom("Helvetica Neue Bold", fixedSize: 15)).shadowStyle()
                Spacer()
            }
        }.onAppear() {
            if carrier_id == "" {
                carrier_id = oldmusic_carrier_name()
            }
            configureNetworkMonitor(completion: {result in
                wifi_connected = result
            })
            UIDevice.current.isBatteryMonitoringEnabled = true
            if (UIDevice.current.batteryState != .unplugged) {
                battery_level = 100
                charging = true
            } else {
                battery_level = UIDevice.current.batteryLevel * 100
            }
        }
    }
    func timeString(date: Date) -> String {
        timeFormat.string(from: date)
    }
}

extension View {
    func shadowStyle() -> some View {
        self.modifier(Shadow())
    }
}

struct Shadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.white.opacity(0.5), radius: 0, x: 0, y: 1)
    }
}

//Yes, all this for a battery
struct battery_in_app: View {
    var battery = Float()
    var charging = Bool()
    let rect = CGRect(x: 0, y: 0, width: 17, height: 6.5)
    var body: some View {
        HStack {
            ZStack {
                Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 77/255, green: 77/255, blue: 79/255), Color.init(red: 77/255, green: 77/255, blue: 79/255), Color.init(red: 198/255, green: 198/255, blue: 198/255)]), startPoint: .top, endPoint: .bottom)).innerShadow2(color:Color.init(red: 51/255, green: 53/255, blue: 58/255), radius: 0.2).overlay(RoundedRectangle(cornerRadius:0.25).stroke(LinearGradient(gradient: Gradient(colors: [Color.init(red: 39/255, green: 41/255, blue: 47/255), Color.init(red: 95/255, green: 101/255, blue: 116/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 1.25)).frame(width: 23.0, height: 12.25).shadowStyle()
                Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 107/255, green: 208/255, blue: 55/255), Color.init(red: 215/255, green: 252/255, blue: 180/255), Color.init(red: 134/255, green: 226/255, blue: 73/255), Color.init(red: 68/255, green: 163/255, blue: 29/255)]), startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.73))).innerShadow2(color: Color.init(red: 220/255, green: 255/255, blue: 177/255), radius: 0.2).frame(width: 21.5*CGFloat(battery), height: 12.25-1.5).offset(x:(-21.5/2)+(21.5/2)*CGFloat(battery)) .applyModifier(charging) {  AnyView($0.overlay(ZStack {Image(systemName:"bolt.fill").resizable().frame(width: 8, height: 12.25-2.5)}.frame(width: 21.5*CGFloat(battery), height: 12.25-1.5).foregroundColor(.black)))
                }
            }

            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 250/255, green: 250/255, blue: 250/255), Color.init(red: 149/255, green: 149/255, blue: 149/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius:0.25).stroke(LinearGradient(gradient: Gradient(colors: [Color.init(red: 39/255, green: 41/255, blue: 47/255), Color.init(red: 95/255, green: 101/255, blue: 116/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 1)).frame(width: 3, height: 5).offset(x:-7.95)
        }
    }
}

//MARK: - Black (Now Playing / Cover Flow) status bar — from HomeScreen.swift

struct status_bar: View {
    @State var date = Date()
    var locked = false
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var battery_level = UIDevice.current.batteryLevel * 100
    @State var carrier_id: String = oldmusic_carrier_name()
    @State var charging: Bool = false
    @State var wifi_connected : Bool = true
    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
            HStack {
                Text(carrier_id == "" ? "No SIM" : carrier_id == "--" ? "eSIM" : carrier_id).foregroundColor(Color.init(red: 200/255, green: 200/255, blue: 200/255)).font(.custom("Helvetica Neue Medium", fixedSize: 15)).onAppear() {
                    carrier_id = oldmusic_carrier_name()
                }
                Image(systemName: "wifi").foregroundColor(Color.init(red: 190/255, green: 190/255, blue: 190/255)).opacity(wifi_connected ? 1 : 0)
                Spacer()
                Text("\(Int(battery_level))%").isHidden(charging).foregroundColor(Color.init(red: 190/255, green: 190/255, blue: 190/255)).font(.custom("Helvetica Neue Medium", fixedSize: 15)).offset(x: 10)
                battery(battery: Float(battery_level/100), charging: charging)
                    .onReceive(timer) { input in
                        if (UIDevice.current.batteryState != .unplugged) {
                            battery_level = 100
                            charging = true
                        } else {
                            battery_level = UIDevice.current.batteryLevel * 100
                            charging = false
                        }
                        date = Date()
                        if carrier_id == "" {
                            carrier_id = oldmusic_carrier_name()
                        }
                        configureNetworkMonitor(completion: {result in
                            wifi_connected = result
                        })
                    }.offset(x: 5)
                //Spacer()
            }.padding([.leading, .trailing], 4)
            HStack {
                Spacer()
                if locked {
                    Image(systemName: "lock.fill").resizable().foregroundColor(Color.init(red: 190/255, green: 190/255, blue: 190/255)).frame(width: 10, height: 14)
                } else {
                    Text(timeString(date: date).uppercased()).foregroundColor(Color.init(red: 190/255, green: 190/255, blue: 190/255)).font(.custom("Helvetica Neue Medium", fixedSize: 15))
                }
                Spacer()
            }
        }.onAppear() {
            if carrier_id == "" {
                carrier_id = oldmusic_carrier_name()
                if carrier_id == "--" {
                    carrier_id = "ESIM"
                }
            }
            configureNetworkMonitor(completion: {result in
                wifi_connected = result
            })
            UIDevice.current.isBatteryMonitoringEnabled = true
            if (UIDevice.current.batteryState != .unplugged) {
                battery_level = 100
                charging = true
            } else {
                battery_level = UIDevice.current.batteryLevel * 100
            }
        }
    }
    func timeString(date: Date) -> String {
        timeFormat.string(from: date)
    }
}

struct battery: View {
    var battery = Float()
    var charging = Bool()
    let rect = CGRect(x: 0, y: 0, width: 17, height: 6.5)
    var body: some View {
        HStack {
            ZStack {
                Rectangle().overlay(RoundedRectangle(cornerRadius:0.25).stroke(Color.init(red: 190/255, green: 190/255, blue: 190/255), lineWidth: 1.25)).foregroundColor(.clear).frame(width: 23.0, height: 12.25)
                Rectangle().frame(width: 18.5*CGFloat(battery), height: 8).foregroundColor(battery <= 0.20 ? .red : Color.init(red: 190/255, green: 190/255, blue: 190/255)).offset(x:(-18.5/2)+(18.5/2)*CGFloat(battery)) .applyModifier(charging) {  AnyView($0.mask(ZStack {Image(systemName:"bolt.fill").resizable().frame(width: 8, height: 7)}.frame(width: 18.5*CGFloat(battery), height: 8).foregroundColor(.black).background(Color.white)                .compositingGroup().luminanceToAlpha()))
                }
            }
            Rectangle().overlay(RoundedRectangle(cornerRadius:0.25).stroke(Color.init(red: 190/255, green: 190/255, blue: 190/255), lineWidth: 1)).foregroundColor(.clear).frame(width: 3, height: 5).offset(x:-7.95)
        }
    }
}

//MARK: - Network monitor (fixed: one shared monitor instead of one per second)

final class OldMusicNetworkMonitor {
    static let shared = OldMusicNetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.iamgasgass.oldmusic.network")
    private let lock = NSLock()
    private var _wifi_connected: Bool = true
    var wifi_connected: Bool {
        lock.lock(); defer { lock.unlock() }
        return _wifi_connected
    }
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let result = path.status == .satisfied && path.usesInterfaceType(.wifi)
            self.lock.lock()
            self._wifi_connected = result
            self.lock.unlock()
        }
        monitor.start(queue: queue)
    }
}

func configureNetworkMonitor(completion: @escaping (Bool)->()) {
    let result = OldMusicNetworkMonitor.shared.wifi_connected
    if Thread.isMainThread {
        completion(result)
    } else {
        DispatchQueue.main.async {
            completion(result)
        }
    }
}

//MARK: - Lists

//Thank you to https://medium.com/macoclock/how-to-remove-line-separator-below-list-using-swiftui-466025c1b8b1 for this
struct NoSepratorList<Content>: View where Content: View {

    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content

    }

    var body: some View {
        if #available(iOS 14.0, *) {
           ScrollView {
               LazyVStack(spacing: 0) {
                self.content().transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
             }
           }
        } else {
            List {
                self.content()
            }
            .onAppear {
               UITableView.appearance().separatorStyle = .none
            }.onDisappear {
               UITableView.appearance().separatorStyle = .singleLine
            }
        }
    }
}

extension View {
    public func gradientForegroundNonDynamic(colors: [Color]) -> some View {
        self.overlay(LinearGradient(gradient: .init(colors: colors),
                                    startPoint: .top,
                                    endPoint: .bottom))
            .mask(self)
    }

}
extension View {
    func innerShadow2(color: Color, radius: CGFloat) -> some View {
        modifier(InnerShadow2(color: color, radius: min(max(0, radius), 1)))
    }
}

private struct InnerShadow2: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1

    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }

    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .top)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .bottom, endPoint: .top)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .bottom)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .leading, endPoint: .trailing)
                            .frame(width: self.radius * self.minSide(geo)),
                         alignment: .leading)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .trailing, endPoint: .leading)
                            .frame(width: self.radius * self.minSide(geo)),
                         alignment: .trailing)
        }
    }

    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}
struct CornerRadiusStyle: ViewModifier {
    var radius: CGFloat
    var corners: UIRectCorner

    struct CornerRadiusShape: Shape {

        var radius = CGFloat.infinity
        var corners = UIRectCorner.allCorners

        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            return Path(path.cgPath)
        }
    }

    func body(content: Content) -> some View {
        content
            .clipShape(CornerRadiusShape(radius: radius, corners: corners))
    }
}

extension View {
    func cornerRadiusSpecific(radius: CGFloat, corners: UIRectCorner) -> some View {
        ModifiedContent(content: self, modifier: CornerRadiusStyle(radius: radius, corners: corners))
    }
}

//MARK: - Sliders

struct CustomSliderComponents {
    let barLeft: CustomSliderModifier
    let barRight: CustomSliderModifier
    let knob: CustomSliderModifier
}
struct CustomSliderModifier: ViewModifier {
    enum Name {
        case barLeft
        case barRight
        case knob
    }
    let name: Name
    let size: CGSize
    let offset: CGFloat

    func body(content: Content) -> some View {
        content
        .frame(width: size.width)
        .position(x: size.width*0.5, y: size.height*0.5)
        .offset(x: offset)
    }
}

struct CustomSlider<Component: View>: View {
    @Binding var value: Double
    @Binding var should_update_from_timer: Bool?
    @Binding var duration: Double?
    var type: String
    var range: (Double, Double)
    var knobWidth: CGFloat?
    let viewBuilder: (CustomSliderComponents) -> Component

    init(type: String, should_update_from_timer: Binding<Bool?> = .constant(true), duration: Binding<Double?> = .constant(0), value: Binding<Double>, range: (Double, Double), knobWidth: CGFloat? = nil,
         _ viewBuilder: @escaping (CustomSliderComponents) -> Component
    ) {
        self.type = type
        _should_update_from_timer = should_update_from_timer
        _duration = duration
        _value = value
        self.range = range
        self.viewBuilder = viewBuilder
        self.knobWidth = knobWidth
    }

    var body: some View {
      return GeometryReader { geometry in
        self.view(geometry: geometry) // function below
      }
    }


    private func view(geometry: GeometryProxy) -> some View {
        var frame = geometry.frame(in: .local)
        if type == "Song" {
           frame = geometry.frame(in: .local)
        } else {
     frame = geometry.frame(in: .global)
        }
      let drag = DragGesture(minimumDistance: 0).onChanged({ drag in
        self.onSliderDragChange(drag, frame) }
      ).onEnded({ _ in
        if type == "Song" {
            //Seek once, on the main thread, where the drag ended.
            let target = max(0, min(1, self.value / 100)) * (self.duration ?? 0)
            MPMusicPlayerController.systemMusicPlayer.currentPlaybackTime = target
            let resume = self.$should_update_from_timer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                resume.wrappedValue = true
            }
       }
      })
      let offsetX = self.getOffsetX(frame: frame)

      let knobSize = CGSize(width: knobWidth ?? frame.height, height: frame.height)
      let barLeftSize = CGSize(width: CGFloat(offsetX + knobSize.width * 0.5), height:  frame.height)
      let barRightSize = CGSize(width: frame.width - barLeftSize.width, height: frame.height)

      let modifiers = CustomSliderComponents(
          barLeft: CustomSliderModifier(name: .barLeft, size: barLeftSize, offset: 0),
          barRight: CustomSliderModifier(name: .barRight, size: barRightSize, offset: barLeftSize.width),
          knob: CustomSliderModifier(name: .knob, size: knobSize, offset: offsetX))
      return ZStack { viewBuilder(modifiers).gesture(drag) }
    }
    private func onSliderDragChange(_ drag: DragGesture.Value,_ frame: CGRect) {
        let width = (knob: Double(knobWidth ?? frame.size.height), view: Double(frame.size.width))
        let xrange = (min: Double(0), max: Double(width.view - width.knob))
        guard xrange.max > xrange.min else { return }
        var value = Double(drag.startLocation.x + drag.translation.width) // knob center x
        value -= 0.5*width.knob // offset from center to leading edge of knob
        value = value > xrange.max ? xrange.max : value // limit to leading edge
        value = value < xrange.min ? xrange.min : value // limit to trailing edge
        value = value.convert(fromRange: (xrange.min, xrange.max), toRange: range)
        if type == "Song" {
            should_update_from_timer = false
        }
        self.value = value
        if type == "Brightness" {
            UIScreen.main.brightness = CGFloat(value/100)
        }
        if type == "Volume" {
        MPVolumeView.setVolume(Float(value/100))
        }
    }
    private func getOffsetX(frame: CGRect) -> CGFloat {
        let width = (knob: knobWidth ?? frame.size.height, view: frame.size.width)
        let xrange: (Double, Double) = (0, Double(max(0, width.view - width.knob)))
        let clamped = min(max(self.value.isFinite ? self.value : 0, range.0), range.1)
        let result = clamped.convert(fromRange: range, toRange: xrange)
        return CGFloat(result.isFinite ? result : 0)
    }
}

extension Double {
    func convert(fromRange: (Double, Double), toRange: (Double, Double)) -> Double {
        var value = self
        value -= fromRange.0
        value /= Double(fromRange.1 - fromRange.0)
        value *= toRange.1 - toRange.0
        value += toRange.0
        return value
    }
}

//MARK: - Volume

extension MPVolumeView {
    /// One persistent, (almost) invisible volume view that lives inside the key window.
    /// Keeping it in the hierarchy also suppresses the modern system volume HUD,
    /// exactly like on iOS 6 where the iPod volume slider was the only feedback.
    static let oldmusic_shared: MPVolumeView = {
        let view = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 120, height: 40))
        view.alpha = 0.0001
        view.isUserInteractionEnabled = false
        view.clipsToBounds = true
        return view
    }()

    static func oldmusic_install(in window: UIWindow?) {
        guard let window = window else { return }
        if oldmusic_shared.superview !== window {
            oldmusic_shared.removeFromSuperview()
            window.addSubview(oldmusic_shared)
        }
    }

    static func setVolume(_ volume: Float) -> Void {
        let volumeView = oldmusic_shared
        if volumeView.superview == nil {
            let window = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
            oldmusic_install(in: window)
        }
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = min(max(volume, 0), 1)
        }
    }
}

final class VolumeObserver: ObservableObject {

    @Published var volume: Float = AVAudioSession.sharedInstance().outputVolume *  100

    private let session = AVAudioSession.sharedInstance()
    private var progressObserver: NSKeyValueObservation?

    func subscribe() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient, options: [.mixWithOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("cannot activate session")
        }

        progressObserver = session.observe(\.outputVolume) { [weak self] (session, value) in
            DispatchQueue.main.async {
                self?.volume = session.outputVolume * 100
            }
        }
    }

    func unsubscribe() {
        self.progressObserver?.invalidate()
    }

    init() {
        subscribe()
    }

    deinit {
        progressObserver?.invalidate()
    }
}

extension Float {
     var double: Double {
         get { Double(self) }
         set { self = Float(newValue) }
     }
 }

extension CGFloat {
     var double: Double {
         get { Double(self) }
         set { self = CGFloat(newValue) }
     }
 }

//MARK: - Inner shadows

extension View {
    func innerShadowBottom(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(InnerShadow_Bottom(color: color, radius: min(max(0, radius), 1)))
    }
    func innerShadowBottomView(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(InnerShadow_Bottom_View(color: color, radius: min(max(0, radius), 1)))
    }
    func innerShadowBottomWithOffset(color: Color, radius: CGFloat = 0.1, offset: CGFloat) -> some View {
        modifier(InnerShadow_Bottom_With_Offset(color: color, radius: min(max(0, radius), 1), offset: offset))
    }
}

private struct InnerShadow_Bottom: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1

    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }

    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .top)
        }
    }

    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}

private struct InnerShadow_Bottom_With_Offset: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1
    var offset: CGFloat = 0.1
    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }

    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                            .frame(height: self.radius * self.minSide(geo)).offset(y:offset),
                         alignment: .top)
        }
    }

    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}
private struct InnerShadow_Bottom_View: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1

    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }

    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .bottom, endPoint: .top)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .bottom)
        }
    }

    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}

//MARK: - Borders

extension View {
    func border_top(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
    func border_bottom(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
    func border_gradient(width: CGFloat, edges: [Edge], color: LinearGradient) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).fill(color))
    }
}
struct EdgeBorder: Shape {

    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: return rect.minX
                case .trailing: return rect.maxX - width
                }
            }

            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: return rect.minY
                case .bottom: return rect.maxY - width
                }
            }

            var w: CGFloat {
                switch edge {
                case .top, .bottom: return rect.width
                case .leading, .trailing: return self.width
                }
            }

            var h: CGFloat {
                switch edge {
                case .top, .bottom: return self.width
                case .leading, .trailing: return rect.height
                }
            }
            path.addPath(Path(CGRect(x: x, y: y, width: w, height: h)))
        }
        return path
    }
}

//MARK: - Misc view helpers

extension View {
   @ViewBuilder
   func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            content(self)
        } else {
            self
        }
    }
}

extension View {

    func applyModifier(_ condition:Bool, apply:(AnyView) -> (AnyView)) -> AnyView {
        if condition {
            return apply(AnyView(self))
        }
        else {
            return AnyView(self)
        }
    }
    @ViewBuilder func isHidden(_ hidden: Bool, remove: Bool = false) -> some View {
        if hidden {
            if !remove {
                self.hidden()
            }
        } else {
            self
        }
    }
}

extension Collection {

    subscript(optional i: Index) -> Iterator.Element? {
        return self.indices.contains(i) ? self[i] : nil
    }

}
