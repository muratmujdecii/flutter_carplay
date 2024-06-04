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
    public func openMap(latitude: Double, longitude: Double, address: String) {
        print("\(latitude) : \(longitude) : \(address) launched")
        let appleMapsURL = URL(string: "http://maps.apple.com/?q=\(address)&ll=\(latitude),\(longitude)")!
        let googleMapsURL = URL(string: "comgooglemaps://?daddr=\(latitude),\(longitude)&directionsmode=driving")!
        
        let canOpenGoogle = UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!)
        let canOpenAppleMaps = UIApplication.shared.canOpenURL(URL(string: "http://maps.apple.com/")!)

        if canOpenGoogle {
            FlutterCarPlaySceneDelegate.shared.carplayScene?.open(googleMapsURL, options: UIScene.OpenExternalURLOptions(), completionHandler: { (Void) in print("completed!") })
        } else if canOpenAppleMaps {
            FlutterCarPlaySceneDelegate.shared.carplayScene?.open(appleMapsURL, options: UIScene.OpenExternalURLOptions(), completionHandler: { (Void) in print("completed!") })
        } else {
            print("No map application can be opened.")
        }
        
        print("Apple Maps URL: \(appleMapsURL)")
        print("Google Maps URL: \(googleMapsURL)")
    }
    
    static public func getConnectionStatus() -> String {
        return carplayConnectionStatus;
    }

    
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                    didConnect interfaceController: CPInterfaceController) {
        print("FCPConnectionTypes.connected")
        
        FlutterCarPlaySceneDelegate.interfaceController = interfaceController
        FlutterCarPlaySceneDelegate.carplayConnectionStatus = FCPConnectionTypes.connected
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
        let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate
        FlutterCarPlaySceneDelegate.shared.carplayScene = templateApplicationScene
        
        if rootTemplate != nil {
          FlutterCarPlaySceneDelegate.interfaceController?.setRootTemplate(rootTemplate!, animated: SwiftFlutterCarplayPlugin.animated, completion: nil)
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
