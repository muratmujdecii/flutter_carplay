//
//  FlutterCarPlayPluginsSceneDelegate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FlutterCarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    static private var interfaceController: CPInterfaceController?
    
    private var carplayScene: CPTemplateApplicationScene?
    static private var carplayConnectionStatus: String = FCPConnectionTypes.disconnected

    static let shared = FlutterCarPlaySceneDelegate()

    private override init() {
           super.init()
       }
    
    static public func forceUpdateRootTemplate() {
        let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate
        let animated = SwiftFlutterCarplayPlugin.animated
            
        self.interfaceController?.setRootTemplate(rootTemplate!, animated: animated)
    }
    
    static public func updateFilterTab(updatedTemplate: FCPListTemplate) {
        let tabbarTemplate = (SwiftFlutterCarplayPlugin.rootTemplate as! CPTabBarTemplate)
        let templates = tabbarTemplate.templates
        let image = UIImage(systemName: "list.bullet")
        let index = templates.firstIndex(where: {$0.tabImage?.pngData() == image?.pngData()})
        let filterTab = templates[index!] as! CPListTemplate
        filterTab.updateSections(updatedTemplate.get.sections)
    }
    
    static public func updatePoiList(updatedPoi: CPPointOfInterestTemplate) {
        let tabbarTemplate = (SwiftFlutterCarplayPlugin.rootTemplate as! CPTabBarTemplate)
        let templates = tabbarTemplate.templates
        let pngData = UIImage(systemName: "ev.charger.fill")?.pngData()
        let poiTab = templates.first(where: {$0.tabImage?.pngData() == pngData}) as! CPPointOfInterestTemplate
        let selectedIndex = poiTab.selectedIndex
        poiTab.setPointsOfInterest(updatedPoi.pointsOfInterest, selectedIndex: selectedIndex)
    }
    
    static public func updateFavPoiTab(updatedPoi: CPPointOfInterestTemplate) {
        let tabbarTemplate = (SwiftFlutterCarplayPlugin.rootTemplate as! CPTabBarTemplate)
        let templates = tabbarTemplate.templates
        let pngData = UIImage(systemName: "heart.fill")?.pngData()
        let poiTab = templates.first(where: {$0.tabImage?.pngData() == pngData}) as! CPPointOfInterestTemplate
        
        let selectedIndex = poiTab.selectedIndex
        poiTab.setPointsOfInterest(updatedPoi.pointsOfInterest, selectedIndex: selectedIndex)
    }
    
    static public func updateChargingTab(updatedTemplate: CPListTemplate) {
        let current = SwiftFlutterCarplayPlugin.chargingList
        let updated = updatedTemplate
        current?.updateSections(updated.sections)
    }
    
    // Fired when just before the carplay become active
    func sceneDidBecomeActive(_ scene: UIScene) {
        FlutterCarPlaySceneDelegate.carplayConnectionStatus = FCPConnectionTypes.connected
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
    }
    
    // Fired when carplay entered background
    func sceneDidEnterBackground(_ scene: UIScene) {
        FlutterCarPlaySceneDelegate.carplayConnectionStatus = FCPConnectionTypes.background
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.background)
    }
    
    
    static public func pop(animated: Bool) {
        self.interfaceController?.popTemplate(animated: animated)
    }
    
    static public func popToRootTemplate(animated: Bool) {
        self.interfaceController?.popToRootTemplate(animated: animated)
    }
    
    static public func push(template: CPTemplate, animated: Bool) {
        self.interfaceController?.pushTemplate(template, animated: animated)
    }
    
    static public func closePresent(animated: Bool) {
        self.interfaceController?.dismissTemplate(animated: animated)
    }
    
    static public func presentTemplate(template: CPTemplate, animated: Bool,
                                       onPresent: @escaping (_ completed: Bool) -> Void) {
        self.interfaceController?.presentTemplate(template, animated: animated, completion: { completed, error in
            guard error != nil else {
                onPresent(false)
                return
            }
            onPresent(completed)
        })
    }
    public func openMap(provider: MapProvider?, latitude: Double, longitude: Double, address: String) {
        guard let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Failed to encode address")
            return
        }
        
        let latString = String(latitude)
        let lonString = String(longitude)
        guard let encodedLat = latString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedLon = lonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Failed to encode coordinates")
            return
        }
        
        let appleMapsURL = URL(string: "http://maps.apple.com/?q=\(encodedAddress)&ll=\(encodedLat),\(encodedLon)")
        let googleMapsURL = URL(string: "comgooglemaps://?daddr=\(encodedLat),\(encodedLon)&directionsmode=driving")
        let yandexMapsURL = URL(string: "yandexmaps://maps.yandex.com/?rtext=\(encodedLat),\(encodedLon)")
        
        let urlsByProvider: [(provider: MapProvider, url: URL?)] = [
            (.google, googleMapsURL),
            (.apple, appleMapsURL),
            (.yandex, yandexMapsURL)
        ]

        let availableProviders: [MapProvider: Bool] = [
            .google: UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!),
            .apple: true, // Apple Maps is always available
            .yandex: UIApplication.shared.canOpenURL(URL(string: "yandexmaps://")!)
        ]

        if let preferredURL = urlsByProvider.first(where: { $0.provider == provider && availableProviders[$0.provider] == true })?.url {
            openMaps(url: preferredURL)
        } else if let fallbackURL = urlsByProvider.first(where: { availableProviders[$0.provider] == true })?.url {
            openMaps(url: fallbackURL)
        } else {
            print("No available map applications.")
        }
    }
    
    private func openMaps(url: URL) {
        carplayScene?.open(url, options: UIScene.OpenExternalURLOptions()) { success in
            if !success {
                print("Failed to open maps URL: \(url)")
            }
        }
    }
    
    
    static public func getConnectionStatus() -> String {
        return carplayConnectionStatus;
    }

    
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                    didConnect interfaceController: CPInterfaceController) {
        print("FCPConnectionTypes.connected")
        
        FlutterCarPlaySceneDelegate.interfaceController = interfaceController
        FlutterCarPlaySceneDelegate.shared.carplayScene = templateApplicationScene
        
        // Set connection status
        FlutterCarPlaySceneDelegate.carplayConnectionStatus = FCPConnectionTypes.connected
        
        // Add a slight delay to ensure proper initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Notify connection change
            SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
            
            // Set root template if available
            if let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate {
                FlutterCarPlaySceneDelegate.interfaceController?.setRootTemplate(
                    rootTemplate,
                    animated: SwiftFlutterCarplayPlugin.animated,
                    completion: { success, error in
                        if let error = error {
                            print("Failed to set root template: \(error)")
                        }
                    }
                )
            } else {
                print("No root template available")
            }
        }
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
        print("FCPConnectionTypes.disconnected")
        FlutterCarPlaySceneDelegate.carplayConnectionStatus = FCPConnectionTypes.disconnected
        FlutterCarPlaySceneDelegate.shared.carplayScene = templateApplicationScene
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)
        
        //FlutterCarPlaySceneDelegate.interfaceController = nil
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        print("FCPConnectionTypes.disconnected 2")
        FlutterCarPlaySceneDelegate.shared.carplayScene = templateApplicationScene
        FlutterCarPlaySceneDelegate.carplayConnectionStatus = FCPConnectionTypes.disconnected
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)
        
        //FlutterCarPlaySceneDelegate.interfaceController = nil
    }
}


enum MapProvider {
    case google
    case apple
    case yandex
    
}
