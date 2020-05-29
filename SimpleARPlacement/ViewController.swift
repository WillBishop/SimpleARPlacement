import UIKit
import RealityKit
import ARKit

class ViewController: UIViewController {
    
    var arView: ARView!
    var configuration: ARWorldTrackingConfiguration {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.initialWorldMap = nil
        config.frameSemantics.insert(.personSegmentationWithDepth)
        config.sceneReconstruction = .mesh
        config.environmentTexturing = .automatic
        return config
    }
    
    //MARK: Raycast Trackers
    var activeRaycasts = [ARTrackedRaycast]()
    var activeEntities = [(ARTrackedRaycast, AnchorEntity)]()
    init() {
        self.arView = ARView()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (_) in //We need to wait to add the ARView, otherwise it'll crash
            self.setupARView()
        }
    }
    
    func setupARView() {
        self.view.addSubview(self.arView)
        arView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.arView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.arView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.arView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.arView.topAnchor.constraint(equalTo: self.view.topAnchor)
        ])
        arView.debugOptions.insert(.showSceneUnderstanding)
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        arView.session.run(configuration, options: [.stopTrackedRaycasts])
        
        let rayCastRecogniser = UITapGestureRecognizer(target: self, action: #selector(performRaycast(_:)))
        self.arView.addGestureRecognizer(rayCastRecogniser)
    }
    
    func randomColor() -> UIColor {
        let colors: [UIColor] = [.black, .blue, .brown, .cyan, .green, .link, .magenta, .orange, .purple, .red, .systemBlue, .systemIndigo, .systemPink, .systemTeal, .yellow]
        return colors.randomElement() ?? .red
    }
    
    @objc func performRaycast(_ sender: UITapGestureRecognizer) {
        let newEntity = AnchorEntity()
        let box = MeshResource.generateBox(width: 0.1, height: 0.001, depth: 0.1) // Generate mesh
        var material = UnlitMaterial()
        material.baseColor = .color(randomColor())
        let entity = ModelEntity(mesh: box, materials: [material])
        newEntity.addChild(entity)
        self.arView.scene.addAnchor(newEntity)
        let location = sender.location(in: self.view)
        let trackedRaycast = self.arView.trackedRaycast(from: location, allowing: .existingPlaneGeometry, alignment: .any) { (raycastResults) in
            guard let firstRaycast = raycastResults.first else { return }
            let columns = firstRaycast.worldTransform.columns
            let position = simd_float4x4(
                columns.0,
                columns.1 + 0.3,
                columns.2,
                columns.3
            )
            entity.transform = Transform(matrix: position)
        }
        if let trackedRaycast = trackedRaycast {
            self.activeRaycasts.append(trackedRaycast)
            self.activeEntities.append((trackedRaycast, newEntity))
        }
    }
}
