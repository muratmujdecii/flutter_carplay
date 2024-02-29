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
    
    static public func updateChargingTab(updatedTemplate: CPListTemplate) {
        let current = SwiftFlutterCarplayPlugin.chargingList
        let updated = updatedTemplate
        current?.updateSections(updated.sections)
    }
    
    // Fired when just before the carplay become active
    func sceneDidBecomeActive(_ scene: UIScene) {
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
    }
    
    // Fired when carplay entered background
    func sceneDidEnterBackground(_ scene: UIScene) {
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
        let url = URL(string: "maps://?q=\(address)&ll=\(longitude),\(latitude)")
        carplayScene?.open(url!, options: nil, completionHandler: nil)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                    didConnect interfaceController: CPInterfaceController) {
        FlutterCarPlaySceneDelegate.interfaceController = interfaceController
        
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
        let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate
        
        if rootTemplate != nil {
          FlutterCarPlaySceneDelegate.interfaceController?.setRootTemplate(rootTemplate!, animated: SwiftFlutterCarplayPlugin.animated, completion: nil)
        }
      }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
        self.carplayScene = templateApplicationScene
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)
        
        //FlutterCarPlaySceneDelegate.interfaceController = nil
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.carplayScene = templateApplicationScene
        SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)
        
        //FlutterCarPlaySceneDelegate.interfaceController = nil
    }
}
