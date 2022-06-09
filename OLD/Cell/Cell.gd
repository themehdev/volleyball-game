extends Area2D

class Brain:
	#Activation Functions
	enum {
		SIGMOID,
		TANH,
		RELU
	}
	
	const E = 2.71828
	
	func sigmoid(x):
		return 1 / (pow(E, -x) + 1)

	func tan_h(x):
		return (pow(E, x) - pow(E, -x)) / (pow(E, -x) + pow(E, x))
	
	var network = {
		"layers": {
			"input": [],
			"deep": [],
			"output": []
		}
	}
	
	func get_neuron(pos:Vector2):
		var layer = network.layers.input if pos[0] == 0 else network.layers.deep if pos[0] > 1 else network.layers.output
		return layer[pos[1]]
	
	func add_input(type:String):
		network.layers.input.append({"type": type, "value": 0, "synapses": {"to": []}})
	
	func add_neuron(act = SIGMOID):
		network.layers.deep.append({"activation": act, "value": 0, "synapses": {"from": [], "to": []}})
	
	func add_output(type:String, act = SIGMOID):
		network.layers.output.append({"type": type, "activation": act, "value": 0, "synapses": {"from": []}})

	func add_synapse(from:Vector2, to:Vector2, weight):
		get_neuron(from).synapses.to.append({"neuron": to, "weight": weight})
		get_neuron(to).synapses.from.append({"neuron": from, "weight": weight})
	
	func init():
		add_input("constant")
		add_output("accel", SIGMOID)
		add_neuron(SIGMOID)
		add_synapse(Vector2(0, 0), Vector2(2, 0), 0.8)
		add_synapse(Vector2(2, 0), Vector2(1, 0), 0.2)
	
	func get_inputs():
		return {
			"constant": 1
		}
	
	func update_input_layer(inputs):
		for n in network.layers.input:
			n.value = inputs[n.type]
	
	func process_neuron(neuron, act = SIGMOID):
		var weighted_sum = 0
		for s in neuron.synapses.from:
			var b_neuron = get_neuron(s.neuron)
			weighted_sum += b_neuron.value * s.weight
		if act == TANH:
			neuron.value = tan_h(weighted_sum)
		elif act == SIGMOID:
			neuron.value = sigmoid(weighted_sum)
		elif act == RELU:
			neuron.value = max(0, neuron.value)
	
	func process_network(inputs):
		update_input_layer(inputs)
		
		var to_update = []
		for i in network.layers.input:
			for s in i.synapses.to:
				to_update.append(get_neuron(s.neuron))
		
		var outputs = {}
		
		while to_update.size() > 0:
			var neuron = to_update[0]
			process_neuron(neuron, SIGMOID)
			if "to" in neuron.synapses:
				for s in neuron.synapses.to:
					to_update.append(get_neuron(s.neuron))
			else:
				outputs[neuron.type] = neuron.value
			to_update.remove(0)
		
		return outputs

var brain = Brain.new()

var genes = {
	"speed": 50,
	"turning_speed": 0.01,
}

var energy = 100
var life = 100
var power = 50
var torque = 0.3
var friction = 0.1
var vel = Vector2()
var ang_vel = 0

func _ready():
	brain.init()
	print(brain.process_network(brain.get_inputs()))

func _physics_process(delta):
	if Input.is_key_pressed(KEY_W):
		vel += Vector2(power, 0).rotated(rotation)
	if Input.is_key_pressed(KEY_S):
		vel -= Vector2(power, 0).rotated(rotation)
	if Input.is_key_pressed(KEY_A):
		ang_vel -= torque
	if Input.is_key_pressed(KEY_D):
		ang_vel += torque
	position += vel * delta
	rotation += ang_vel * delta
	vel *= 1 - friction
	ang_vel *= 1 - friction
	
