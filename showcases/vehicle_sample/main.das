require engine.core

var camera : NodeId
var statusNode : NodeId
var vehicleNode : NodeId

var cameraRotationAngle = 0.

var handbrake : bool

let CAMERA_OFFSET = float3(0.1, 1.5, -2.5)
let CAMERA_X_ROT = PI * 0.15

[export] def on_initialize() {
    statusNode = create_debug_text(float2(20, -20), BOTTOM_LEFT_ANCHOR)
    statusNode?.UIText.color = BLACK_COLOR

    init_scene()
    init_input()
    init_vehicle()

    camera = create_node(NodeData(name = "camera"))
    add_component(camera, new Camera())

    let plane = create_node(NodeData(position = float3(3, 0.15, 5), rotation = quat4(deg_to_rad(-15.), 0, 0), scale = float3(6, 1, 5)))
    add_component(plane, new Mesh(meshId = CUBE_MESH_ID))
    add_component(plane, new Collider(shape = box_shape()))

    set_physics_fps(100f)
}

def init_input() {
    add_and_activate_action_set("playerInput", {
        "gas" => Action(
            axisActions = AxisAction(
                keyboardAxis = [KeyboardBtnAxisInput(positiveIdx=KeyCode.Up, negativeIdx=KeyCode.Down)],
            )
        ),
        "steering" => Action(
            axisActions = AxisAction(
                keyboardAxis = [KeyboardBtnAxisInput(positiveIdx=KeyCode.Right, negativeIdx=KeyCode.Left)],
            )
        ),
        "handbrake" => Action(
            buttonActions = ButtonAction(
                keyboardButtons = [KeyboardButtonInput(idx=KeyCode.Space)],
                gamepadButtons = [GamepadButtonInput(idx=GamepadButton.X)]
            )
        )
    })
}

def init_vehicle() {
    vehicleNode = create_node(NodeData(name = "vehicle", position = float3(0, 10, 0)))
    add_component(vehicleNode, new VehicleController(wheels = [
        VehicleWheel(position = float3(-1, 0, 1), radius = 0.25, maxSteeringAngle = 0.25 * PI),
        VehicleWheel(position = float3(1, 0, 1), radius = 0.25, maxSteeringAngle = 0.25 * PI),
        VehicleWheel(position = float3(-1, 0, -1), radius = 0.25, maxSteeringAngle = 0.),
        VehicleWheel(position = float3(1, 0, -1), radius = 0.25, maxSteeringAngle = 0.),
    ]))
    add_component(vehicleNode, new Mesh(meshId = CUBE_MESH_ID))
    add_component(vehicleNode, new Collider(shape = box_shape()))
    add_component(vehicleNode, new RigidBody())
}

[export]
def on_update() {
    let gas = get_action_axis("gas")
    let steer = get_action_axis("steering")

    if (is_action_just_pressed("handbrake")) {
        handbrake = !handbrake
    }

    vehicleNode?.VehicleController.gasInput = move_to(vehicleNode?.VehicleController.gasInput, max(gas, 0.), get_delta_time(), 1.)
    vehicleNode?.VehicleController.brakeInput = move_to(vehicleNode?.VehicleController.brakeInput, max(-gas, 0.), get_delta_time(), 10.)
    vehicleNode?.VehicleController.steeringInput = move_to(vehicleNode?.VehicleController.steeringInput, steer, get_delta_time(), 1.)
    vehicleNode?.VehicleController.handbrakeInput = move_to(vehicleNode?.VehicleController.handbrakeInput, handbrake ? 1. : 0., get_delta_time(), 10.)
    update_debug_text(statusNode, "Gas: {vehicleNode?.VehicleController.gasInput}\nSteering: {vehicleNode?.VehicleController.steeringInput}\nBrake: {vehicleNode?.VehicleController.brakeInput}, Handbrake: {vehicleNode?.VehicleController.handbrakeInput}\nRPM: {vehicleNode?.VehicleController.currentRPM}")

    camera.worldPosition = vehicleNode.worldPosition + cross(vehicleNode.localRight, UP) * CAMERA_OFFSET.z + cross(-vehicleNode.localForward, UP) * CAMERA_OFFSET.x + UP * CAMERA_OFFSET.y
    let newCameraRotationAngle = quat_to_euler(vehicleNode.worldRotation).y
    cameraRotationAngle = angle_approach(cameraRotationAngle, newCameraRotationAngle, get_delta_time(), 0.1)
    camera.worldRotation = quat4(CAMERA_X_ROT, cameraRotationAngle, 0)
}

def init_scene() {
    let scale = float3(400f, 0.1f, 400f)
    let angle = 0f // PI * -0.125f
    let plane = create_node(NodeData(rotation = quat4(0f, 0f, angle), scale = scale))
    add_component(plane, new Mesh(meshId = CUBE_MESH_ID))
    add_component(plane, new Collider(shape = box_shape(scale)))

    let sunDirection = float3(PI / 12f, -PI * 0.25f, 0f)
    let sun = create_node(NodeData(rotation = quat4(sunDirection)))
    add_component(sun, new DirectionLight())

    let renderSettings = create_render_settings()

    get_component(renderSettings) $(var shadow : ShadowSettings?) {
        shadow.powWeight = 0.6f
        shadow.maxDist = 550f
        shadow.numCascades = 4
    }
}


